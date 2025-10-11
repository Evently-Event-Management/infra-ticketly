export const pollUntil = async (check: () => Promise<boolean>, timeout = 20000, interval = 1000) => {
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
        if (await check()) return;
        await new Promise(resolve => setTimeout(resolve, interval));
    }
    throw new Error("Polling for async operation timed out.");
};

export const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));