// Twitch may initialize after the page finishes loading. Keep the latest
// settings until the player reports that it can accept commands.
if (!window.action) {
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

  var playerReady = false;
  var pendingActions = new Map();

  function sendAction(eventName, params) {
    ifr.contentWindow.postMessage(
      { eventName, params, namespace: "twitch-embed-player-proxy" },
      "*",
    );
  }

  window.action = function (eventName, params) {
    if (playerReady) {
      sendAction(eventName, params);
    } else {
      pendingActions.set(eventName, params);
    }
  };

  window.addEventListener("message", function (event) {
    var data = event.data;
    if (!data || event.source !== ifr.contentWindow) return;
    if (
      (data.namespace === "twitch-embed" && data.eventName === "ready") ||
      (data.namespace === "twitch-embed-player-proxy" &&
        data.params &&
        data.params.playback &&
        data.params.playback !== "Idle")
    ) {
      playerReady = true;
      pendingActions.forEach(function (params, eventName) {
        sendAction(eventName, params);
      });
      pendingActions.clear();
    }
  });

  if (typeof Flutter !== "undefined") {
    window.addEventListener(
      "message",
      (e) => Flutter.postMessage(JSON.stringify(e.data)),
      false,
    );
  }
}
