/**
 * Runs in Node when Expo starts. `.env` is loaded first, so `VITE_*` from your web
 * project works here — we copy API origin/prefix into `extra` for the JS bundle.
 */
const appJson = require('./app.json');

function stripTrailingSlash(s) {
  return String(s).replace(/\/$/, '');
}

const apiOrigin = stripTrailingSlash(
  process.env.EXPO_PUBLIC_API_ORIGIN ||
    process.env.VITE_API_BASE_URL ||
    'http://127.0.0.1:8000',
);

let apiPrefix = process.env.EXPO_PUBLIC_API_PREFIX || process.env.VITE_API_PREFIX || '/api/v1';
if (!apiPrefix.startsWith('/')) {
  apiPrefix = `/${apiPrefix}`;
}

/** Set by `eas build:configure` — required so EAS can link this repo to your cloud project. */
const easProjectId = 'f09c080f-1a56-4e93-a997-4a9c91bb9eb6';

module.exports = {
  expo: {
    ...appJson.expo,
    extra: {
      ...(appJson.expo.extra || {}),
      apiOrigin,
      apiPrefix,
      eas: {
        ...(appJson.expo.extra && appJson.expo.extra.eas ? appJson.expo.extra.eas : {}),
        projectId: easProjectId,
      },
    },
    /** Required for expo-secure-store native config when using a dynamic app.config.js */
    plugins: [...(appJson.expo.plugins || []), 'expo-secure-store'],
  },
};
