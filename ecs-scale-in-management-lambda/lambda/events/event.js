const inputBody = () => {
    return {
        body: {
            policyNames: "product-manager-scaling-number-of-requests-per-target",
            disableScaleIn: true,
        }
    };
};

exports.inputBody = inputBody;

