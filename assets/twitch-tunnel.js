// inject iframe

var ifr = document.createElement("iframe");
ifr.srcdoc = `
<script>
  window.addEventListener(
    "message",
    (e) => window.parent.postMessage(e.data, "*"),
    false
  );
</script>
`;
ifr.style.visibility = "hidden";
document.body.appendChild(ifr);

window.parent = ifr.contentWindow;

window.Actions = {
  DisableCaptions: 0,
  EnableCaptions: 1,
  Pause: 2,
  Play: 3,
  Seek: 4,
  SetChannel: 5,
  SetChannelID: 6,
  SetCollection: 7,
  SetQuality: 8,
  SetVideo: 9,
  SetMuted: 10,
  SetVolume: 11,
};

window.action = function(eventName, params) {
  ifr.contentWindow.postMessage(
    { eventName, params, namespace: "twitch-embed-player-proxy" },
    "*"
  );
}

if (Flutter) {
  window.addEventListener(
    "message",
    (e) => Flutter.postMessage(JSON.stringify(e.data)),
    false
  );
}
