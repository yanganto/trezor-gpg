browser.tabs.query({
  active: true,
  currentWindow: true,
}).then(tabs => {
  let tabId = tabs[0].id;
  browser.messageDisplay.getDisplayedMessage(tabId).then((message) => {
    // message.subject;
    return browser.messages.getFull(message.id);
    // DEBUG:
    // return browser.messages.getRaw(message.id);
  }).then((r) => {
    // TODO: handle more part sections
    // TODO: open content in tabs
    // TODO: decrypt with trezor
    document.body.textContent = r.parts[0].parts[0].body;
  });
});
