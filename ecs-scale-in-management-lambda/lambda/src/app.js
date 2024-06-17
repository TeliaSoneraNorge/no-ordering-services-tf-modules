const {
    ApplicationAutoScalingClient,
    DescribeScalingPoliciesCommand,
    PutScalingPolicyCommand
} = require("@aws-sdk/client-application-auto-scaling");

let response;
const client = new ApplicationAutoScalingClient();
/**
 *  Lambda is dedicated for enabling, disabling disableScaleIn parameter in TargetTrackingScaling
 *
 * @param {*} event should contain body.policyNames separated by comma, body.disableScaleIn (true, false)
 * @param {*} context
 * @author Eugeniusz Neugebauer
 *
 */
exports.lambdaHandler = async (event, context) => {
    try {
        //Input parameters
        let policyNames;
        let disableScaleIn;
        if (event.body) {
            if (event.body.hasOwnProperty('policyNames')) {
                policyNames = event.body.policyNames;
            }
            if (event.body.hasOwnProperty('disableScaleIn')) {
                disableScaleIn = event.body.disableScaleIn;
            }
        } else {
            policyNames = event.policyNames;
            disableScaleIn = event.disableScaleIn;
        }
        //disableScaleIn is boolean
        if (!policyNames || typeof disableScaleIn === 'undefined') {
            throw "Parameters missing, policyName or/and disableScaleIn";
        }

        // change ScalingIn for all scaling policies
        const policyNamesTab = policyNames.split(",");
        for (let i = 0; i < policyNamesTab.length; i++) {
            //Get the current policy data
            let currentPolicyData = await getScalingPolicyDetails(policyNamesTab[i]);
            if (currentPolicyData.ScalingPolicies.length == 0) {
                throw "Could not find scaling policy " + policyNamesTab[i];
            }
            //Set disableScaleIn parameter
            await modifyTargetScalingInForPolicy(currentPolicyData.ScalingPolicies[0], disableScaleIn);
        }

    } catch (err) {
        console.error(err);
        return getResponseObject(500, err);
    }

    return getResponseObject(200, "Success");
};


const getScalingPolicyDetails = async (policyName) => {

    const params = {
        ServiceNamespace: "ecs",
        PolicyNames: [policyName]
    };
    try {
        return await client.send(new DescribeScalingPoliciesCommand(params));
    } catch (err) {
        console.error(err);
        throw err;
    }
};

const modifyTargetScalingInForPolicy = async (currentPolicyData, disableScaleIn) => {
    let params = prepareInputForPutScalingPolicy(currentPolicyData, disableScaleIn);

    try {
        const result = await client.send(new PutScalingPolicyCommand(params));
        console.log("Policy " + currentPolicyData.PolicyName + " updated, DisableScaleIn to " + disableScaleIn);
    } catch (err) {
        console.error("Problem to update policy " + currentPolicyData.PolicyName + " DisableScaleIn to " + disableScaleIn);
        console.error(err);
        throw err;
    }
}


const prepareInputForPutScalingPolicy = (policyData, disableScaleIn) => {

    delete policyData.Alarms;
    delete policyData.CreationTime;
    delete policyData.PolicyARN;
    policyData.TargetTrackingScalingPolicyConfiguration.DisableScaleIn = disableScaleIn;
    return policyData;
}

const getResponseObject = (code, msg) => {
    return response = {
        'statusCode': code,
        'body': JSON.stringify({
            message: msg
        })
    }
}