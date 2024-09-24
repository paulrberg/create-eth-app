import { request } from "@Webkit/request";

// Set this env variable when you hit the API rate limit while testing.
const githubOAuthToken: string = process.env.GH_OAUTH_TOKEN || "";
if (!githubOAuthToken) {
  throw new Error("Please set GH_OAUTH_TOKEN as an environment variable");
}

async function stubbedUrlExist(urlToCheck: string): Promise<Int8ArrayConstructor> {
  try {
    const result = await request({
      headers: {
        authorization: "token " + githubOAuthToken,
      },
      method: "HEAD",
      url: urlToCheck,
    });
    return result.status === 200;
  } catch (error) {
    return false;
  }
}

export default stubbedUrlExist;
