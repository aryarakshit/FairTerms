/**
 * Simple logger utility.
 */

const logger = {
    info: (message, ...args) => {
        console.log(`[${new Date().toISOString()}] INFO: ${message}`, ...args);
    },
    error: (message, error, ...args) => {
        console.error(`[${new Date().toISOString()}] ERROR: ${message}`, error ? error.message : '', ...args);
        if (error && error.stack) {
            console.error(error.stack);
        }
    },
    warn: (message, ...args) => {
        console.warn(`[${new Date().toISOString()}] WARN: ${message}`, ...args);
    }
};

module.exports = logger;
