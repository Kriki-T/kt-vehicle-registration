const app = document.getElementById("app");
let currentPlate = "";
let currentModel = "";

window.addEventListener("message", (event) => {
  const msg = event.data;

  if (msg.action === "open") {
    currentPlate = msg.plate;
    currentModel = msg.model;

    document.getElementById("plateDisplay").innerText = formatPlate(msg.plate);
    document.getElementById("modelText").innerText = msg.model;

    const badge = document.getElementById("statusBadge");
    const daysLeft = document.getElementById("daysLeft");
    const registerBtn = document.getElementById("registerBtn");
    const renewBtn = document.getElementById("renewBtn");

    if (!msg.data) {
      badge.className = "badge badge-none";
      badge.innerText = "Nije registrovano";
      daysLeft.innerText = "";
      registerBtn.classList.remove("hidden");
      renewBtn.classList.add("hidden");
    } else {
      const expires = new Date(msg.data.expires_at);
      const now = new Date();
      const diffDays = Math.ceil((expires - now) / (1000 * 60 * 60 * 24));

      if (diffDays > 0) {
        badge.className = "badge badge-active";
        badge.innerText = "Aktivna";
      } else {
        badge.className = "badge badge-expired";
        badge.innerText = "Istekla";
      }
      daysLeft.innerText =
        diffDays > 0 ? `${diffDays} dana preostalo` : "Isteklo";
      registerBtn.classList.add("hidden");
      renewBtn.classList.remove("hidden");
    }

    app.classList.remove("hidden");
  }
});

function formatPlate(plate) {
  return plate.replace(/(.{2})(.{3})(.{2})/, "$1 $2 $3");
}

document.getElementById("closeBtn").addEventListener("click", () => {
  fetch(`https://${GetParentResourceName()}/close`, { method: "POST" });
  app.classList.add("hidden");
});

document.getElementById("registerBtn").addEventListener("click", () => {
  fetch(`https://${GetParentResourceName()}/register`, {
    method: "POST",
    body: JSON.stringify({ plate: currentPlate, model: currentModel }),
  });
  app.classList.add("hidden");
});

document.getElementById("renewBtn").addEventListener("click", () => {
  fetch(`https://${GetParentResourceName()}/renew`, {
    method: "POST",
    body: JSON.stringify({ plate: currentPlate }),
  });
  app.classList.add("hidden");
});

function GetParentResourceName() {
  return window.GetParentResourceName
    ? window.GetParentResourceName()
    : "kt-vehicle-registration";
}
