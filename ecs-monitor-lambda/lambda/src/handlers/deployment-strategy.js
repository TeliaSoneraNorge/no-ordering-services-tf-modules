const { ECSClient, DescribeServicesCommand, waitUntilServicesStable } = require("@aws-sdk/client-ecs");
const { CodeDeployClient, ListDeploymentsCommand, waitUntilDeploymentSuccessful, GetDeploymentCommandInput } = require("@aws-sdk/client-codedeploy");

const ecsClient = new ECSClient();
const codeDeployClient = new CodeDeployClient();

class DeploymentStrategy {
    constructor(service, cluster, waiter) {
        this.service = service;
        this.cluster = cluster;
        this.waiter = waiter;
    }

    identify() {
        console.info('Parent');
    }
}


class ClassicStrategy extends DeploymentStrategy {
    constructor(service, cluster, waiter) {
        super(service, cluster, waiter);
    }

    async waitForServiceStability() {
        const params = new DescribeServicesCommand({
            services: [this.service],
            cluster: this.cluster
        });

        const waiterResult = await waitUntilServicesStable(
            {
                ecsClient,
                minDelay: this.waiter.wait_delay_sec,
                maxDelay: this.waiter.wait_delay_sec,
                maxWaitTime: this.waiter.max_wait_minutes * 60
            },
            params);
        return waiterResult;
    }

    identify() {
        return "Classic";
    }
}

class BlueGreenStrategy extends DeploymentStrategy {
    constructor(service, cluster, waiter) {
        super(service, cluster, waiter);
    }

    async waitForServiceStability() {
        const result = await this._getDeploymentId();
        if (result.deployments.length == 0) {
            throw new Error("No BleuGreen deployemts found!");
        }

        //take first in array meaning last one
        const currentDeplId = result.deployments[0];

        const waiterResult = await waitUntilDeploymentSuccessful(
            {
                codeDeployClient,
                minDelay: this.waiter.wait_delay_sec,
                maxDelay: this.waiter.wait_delay_sec,
                maxWaitTime: this.waiter.max_wait_minutes * 60
            },
            new GetDeploymentCommandInput({ deploymentId: currentDeplId }));
        return waiterResult;
    }

    async _getDeploymentId() {
        const input = new ListDeploymentsCommand({
            applicationName: this.service,
            createTimeRange: {
                end: null,
                start: null
            },
            deploymentGroupName: this.service,
            includeOnlyStatuses: ["InProgress"]
        });
        const response = await codeDeployClient.send(input);
        return response;
    }

    identify() {
        return "BlueGreen";
    }
}

class DeploymentStrategyDelegator {

    static CLASSIC(service, cluster, waiter) {
        return new ClassicStrategy(service, cluster, waiter);
    }

    static BLUEGREEN(service, cluster, waiter) {
        return new BlueGreenStrategy(service, cluster, waiter);
    }
}

module.exports = { DeploymentStrategyDelegator }
