const inputBody = () => {
    return {
        body: {
            desiredCount: 1,
            serviceName: "st1-bml",
            clusterName: "st1-cluster"
        }
    };
};

exports.inputBody = inputBody;

