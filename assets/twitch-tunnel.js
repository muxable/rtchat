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


window.detectPlayerCapabilities = function() {
  // Wait for player to be available
  const checkPlayer = setInterval(() => {
    if (window.player && typeof player.getQualities === 'function') {
      clearInterval(checkPlayer);

      try {
        // Get available qualities
        const qualities = player.getQualities().map(q => q.group);

        // Send to Flutter
        if (window.Flutter) {
          Flutter.postMessage(JSON.stringify({
            type: 'playerCapabilities',
            qualities: qualities,
            currentQuality: player.getQuality()
          }));
        }
      } catch (e) {
        console.error('Quality detection failed:', e);
      }
    }
  }, 500);
};

// Initialize when Twitch player is ready
if (typeof Twitch !== 'undefined') {
  Twitch.Player.READY && Twitch.Player.READY(() => {
    window.detectPlayerCapabilities();
  });
}

// Also check when our iframe loads
window.addEventListener('load', () => {
  window.detectPlayerCapabilities();
});

if (Flutter) {
  window.addEventListener(
    "message",
    (e) => Flutter.postMessage(JSON.stringify(e.data)),
    false
  );
}
