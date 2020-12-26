async function encryptMsg() {
  let status = document.getElementById("status");

  let tab = await browser.tabs.query({
    active: true,
    currentWindow: true,
  }).then(tabs => tabs[0]);

  let details = await browser.compose.getComposeDetails(tab.id);
  let body = details.plainTextBody;
  let pk = publicKey.value;
  status.innerHTML = `encrypting with ${pk}... `;
  const { data: encrypted } = await openpgp.encrypt({
    message: openpgp.message.fromText(body),
    publicKeys: (await openpgp.key.readArmored(pk)).keys[0]
  });
  console.log(encrypted);

  browser.compose.setComposeDetails(tab.id, { plainTextBody: encrypted });
  status.innerHTML = "";
}

encryptBTN.addEventListener("click", encryptMsg, false);
