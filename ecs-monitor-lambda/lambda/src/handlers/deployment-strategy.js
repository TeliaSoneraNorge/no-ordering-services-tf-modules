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

        const delay = (seconds) => new Promise((resolve) => setTimeout(resolve, seconds * 1000));
        const maxAttempts = this.waiter.max_wait_minutes * 60 / this.waiter.wait_delay_sec;

        for (let attempt = 0; attempt < maxAttempts; attempt++) {
            try {
                const response = await ecsClient.send(params);
                const service = response.services[0];
                const deployments = service.deployments || [];
                const runningCount = service.runningCount || 0;
                const desiredCount = service.desiredCount || 0;

                if (service && service.status === "ACTIVE" && deployments.length === 1 && runningCount === desiredCount) {
                    return `Service ${this.service} is stable.`;
                }

                console.log(`Waiting for service ${this.service} to stabilize...`);
            } catch (error) {
                console.error("Error checking service status:", error);
            }
            await delay(this.waiter.wait_delay_sec);
        }
        throw new Error(`Timeout before service ${this.service} stablized`);
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
