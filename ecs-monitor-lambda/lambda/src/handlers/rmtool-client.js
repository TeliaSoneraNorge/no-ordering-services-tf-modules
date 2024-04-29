const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");
const https = require('https');

const CLIENT_SECRET_BASE64_PARAM_PATH = process.env.ENV_CLIENT_SECRET_BASE64_PARAM_PATH
const RMTOOL_HOST = process.env.ENV_RMTOOL_HOST

const ssmClient = new SSMClient();

const buildRequestPayload = (phase, status, component, env_action_update) => {
    return {
        name: env_action_update.name,
        build: {
            full_url: env_action_update.full_url,
            number: env_action_update.number,
            phase: phase,
            status: status,
            parameters: {
                deploymentId: env_action_update.deploymentId,
                component: component,
                version: env_action_update.component_version,
                environment: env_action_update.environment,
                action: env_action_update.action,
            },
        },
    }
}

/**
 * Creates request options JSON object
 * @param {*} path The path to be added to host
 * @param {*} method GET|POST|PUT|...
 */
const buildRequestOptions = (path, method, payload) => {
    let options = {
        hostname: RMTOOL_HOST,
        port: 443,
        path: `${path}`,
        headers: {
            "Accept": "application/json"
        },
        method: `${method}`,
    }
    if (payload) {
        options.headers = { ...options.headers, "Content-Type": "application/json" }
        options.headers = { ...options.headers, "Content-Length": JSON.stringify(payload).length }
    }

    return options;
}

/**
 * Creates request options JSON object with Basic Auth
 * @param {*} path
 * @param {*} auth base64 encoded username:secret
 * @param {*} method GET|POST|PUT|...
 */
const buildRequestOptionsWithBasicAuth = (path, auth, method, payload) => {
    let options = buildRequestOptions(path, method, payload);
    options.headers = { ...options.headers, Authorization: `Basic ${auth}` }
    return options;
}

const buildRequestPromise = (options, payload) => {

    return new Promise((resolve, reject) => {
        let req = https.request(options, (res) => {
            res.setEncoding('utf8');
            let response = {
                statusCode: res.statusCode,
                headers: res.headers,
                body: ''
            }

            if (res.statusCode < 200 || res.statusCode >= 300) {
                console.error("Problem with response occurred, response code = " + res.statusCode + ", statusMessage:" + res.statusMessage);
                console.error(res)
                return reject(res);
            }

            res.on('data', (data) => {
                response.body += data;
            });
            res.on('end', function () {
                console.log(JSON.stringify(response));
                if (response.statusCode === 204) {
                    resolve();
                    return;
                }
                resolve(JSON.parse(response.body));
            });
        });

        req.on('error', (err) => {
            reject(err);
        });

        if (payload) {
            req.write(JSON.stringify(payload));
        }
        req.end();
    });
}

const buildRequestPromiseWithBasicAuth = (path, basicAuth, method, payload) => {
    let options = buildRequestOptionsWithBasicAuth(path, basicAuth, method, payload);
    return buildRequestPromise(options, payload);
}

const getBase64EncodedAuthFromParamStore = async () => {
    const input = new GetParameterCommand({
        Name: CLIENT_SECRET_BASE64_PARAM_PATH,
        WithDecryption: true
    });
    const response = await ssmClient.send(input);
    return response;
}

class RMToolClient {

    /**
     * @param {*} basicAuth username:password base64 value
     * @param {*} payload JSON object representing deploy status
     */
    static async actionUpdate(phase, status, component, env_action_update) {
        const path = `/api/rmtool-environmentsActionUpdates`;
        const method = 'POST'

        const basicAuth = (await getBase64EncodedAuthFromParamStore()).Parameter.Value;

        const payload = buildRequestPayload(phase, status, component, env_action_update);
        let data = await buildRequestPromiseWithBasicAuth(path, basicAuth, method, payload);

        return data;
    }
}

module.exports = { RMToolClient }
