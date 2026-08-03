function dispatchUpdateOsobaWorkflow() {
  dispatchGitHubWorkflow_('update-osoba.yml');
}

function dispatchCheckOsobaWorkflow() {
  dispatchGitHubWorkflow_('check-osoba.yml');
}

function dispatchGenerateOtoriyoseWorkflow() {
  dispatchGitHubWorkflow_('generate-otoriyose.yml');
}

function dispatchPublishOtoriyoseWorkflow() {
  dispatchGitHubWorkflow_('publish-otoriyose.yml');
}

function dispatchGitHubWorkflow_(workflowId) {
  const owner = 'shamaton';
  const repo = 'triggers';
  const ref = 'main';

  const token = PropertiesService
    .getScriptProperties()
    .getProperty('GITHUB_TOKEN');

  if (!token) {
    throw new Error('GITHUB_TOKEN is not configured.');
  }

  const url = `https://api.github.com/repos/${owner}/${repo}/actions/workflows/${workflowId}/dispatches`;

  const payload = {
    ref: ref
  };

  const options = {
    method: 'post',
    contentType: 'application/json',
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28'
    },
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };

  const response = UrlFetchApp.fetch(url, options);

  Logger.log(`${workflowId}: ${response.getResponseCode()}`);
  Logger.log(response.getContentText());
}
