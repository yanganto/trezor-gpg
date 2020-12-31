function onResponse(response) {
  console.log(`Response: ${response}`)
  document.body.textContent = response;
}

function onError(error) {
  console.log(`Error: ${error}`);
  document.body.textContent = "Please report the email to https://github.com/yanganto/trezor-gpg/issues\n" +
  `Error: ${error}`;
}

browser.tabs.query({
  active: true,
  currentWindow: true,
}).then(tabs => {
  let tabId = tabs[0].id;
  browser.messageDisplay.getDisplayedMessage(tabId).then((message) => {
    return browser.messages.getFull(message.id);
  }).then((r) => {
    // TODO: handle multi-part
    // TODO: open content in tabs
    let body = r.parts[0].body;
    var sending = browser.runtime.sendNativeMessage(
      "trezor_gpg",
      "decrypt:" + body);
    sending.then(onResponse, onError);
    });
});
