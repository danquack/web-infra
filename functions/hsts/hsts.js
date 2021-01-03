'use strict';
exports.handler = (event, context, callback) => {

    //Get contents of response
    const response = event.Records[0].cf.response;
    const headers = response.headers;

    //Set new headers 
    headers['strict-transport-security'] = [{
        key: 'Strict-Transport-Security',
        value: 'max-age=31536000; includeSubDomains; preload'
    }];
    headers['x-content-type-options'] = [{
        key: 'X-Content-Type-Options',
        value: 'nosniff'
    }];
    headers['x-xss-protection'] = [{
        key: 'X-XSS-Protection',
        value: '1; mode=block'
    }];
    headers['referrer-policy'] = [{
        key: 'Referrer-Policy',
        value: 'same-origin'
    }];

    //Return modified response
    if (event.Records[0].cf.request.uri.endsWith('.gz')) {
        headers['content-encoding'] = [{
            key: 'Content-Encoding',
            value: 'gzip'
        }];
    }
    callback(null, response);
};