let APP_INFO = `
The content of email is encrypted by trezor-gpg
https://github.com/yanganto/trezor-gpg
Donate Bitcoin: 3MMXH72P73ew2c9CQdGHR3uh2LddbCCDxU
`;
async function encryptMsg() {
  let tab = await browser.tabs.query({
    active: true,
    currentWindow: true,
  }).then(tabs => tabs[0]);

  let details = await browser.compose.getComposeDetails(tab.id);
  let body = details.plainTextBody;

  let armored_pk = publicKey.value;
  let pk = (await openpgp.key.readArmored(armored_pk)).keys[0];
  statusP.innerHTML = `encrypting...`;

  const { data: encrypted } = await openpgp.encrypt({
    message: openpgp.message.fromText(body),
    publicKeys: pk
  });
  browser.compose.setComposeDetails(tab.id, { plainTextBody: encrypted + APP_INFO });
  statusP.innerHTML = "";
}

function onResponse(response) {
  console.log("Received " + response);
  statusP.innerHTML = "";
}

function onError(error) {
  console.log(`Error: ${error}`);
  statusP.innerHTML = "Please report to https://github.com/yanganto/trezor-gpg/issues " +
  `Error: ${error}`;
}

async function signMsg() {
  let tab = await browser.tabs.query({
    active: true,
    currentWindow: true,
  }).then(tabs => tabs[0]);

  let details = await browser.compose.getComposeDetails(tab.id);
  let body = details.plainTextBody;

  // TODO: sign the encrypted message
  statusP.innerHTML = `signed message... `;
  var sending = browser.runtime.sendNativeMessage(
    "trezor_gpg",
    "sign:" + body);
  sending.then(onResponse, onError);
}

encryptBTN.addEventListener("click", encryptMsg, false);
signBTN.addEventListener("click", signMsg, false);
