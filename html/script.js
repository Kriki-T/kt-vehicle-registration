const app = document.getElementById("app");
let currentPlate = "";
let currentModel = "";
let verifiedCustomPlate = null;

/* ---------- NUI MESSAGE HANDLER ---------- */
window.addEventListener("message", (event) => {
  const msg = event.data;

  if (msg.action === "open") {
    currentPlate = msg.plate;
    currentModel = msg.model;

    const plateDisplay = document.getElementById("plateDisplay");
    plateDisplay.innerText = formatPlate(msg.plate);

    document.getElementById("modelText").innerText = msg.model;
    document.getElementById("customPlatePreview").innerText = formatPlate(
      msg.plate,
    );

    const badge = document.getElementById("statusBadge");
    const daysLeft = document.getElementById("daysLeft");
    const registerBtn = document.getElementById("registerBtn");
    const renewBtn = document.getElementById("renewBtn");
    const ownerName = document.getElementById("ownerName");
    const vehicleId = document.getElementById("vehicleId");

    if (msg.data && msg.data.personalized) {
      plateDisplay.classList.add("premium");
    } else {
      plateDisplay.classList.remove("premium");
    }

    if (!msg.data) {
      badge.className = "badge badge-none";
      badge.innerText = "Nije registrovano";
      daysLeft.innerText = "";
      registerBtn.classList.remove("hidden");
      renewBtn.classList.add("hidden");
      ownerName.innerText = "—";
      vehicleId.innerText = "—";
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

      ownerName.innerText = msg.data.owner_identifier
        ? msg.data.owner_identifier.slice(0, 10) + "..."
        : "—";
      vehicleId.innerText = msg.data.id || "—";
    }

    resetCustomTab();
    app.classList.remove("hidden");
  }

  if (msg.action === "plateAvailability") {
    handleAvailabilityResult(msg.result);
  }

  if (msg.action === "personalizedSuccess") {
    const plateDisplay = document.getElementById("plateDisplay");
    plateDisplay.innerText = formatPlate(msg.plate);
    plateDisplay.classList.add("premium");
    app.classList.add("hidden");
  }
});

/* ---------- HELPERS ---------- */
function formatPlate(plate) {
  return plate.replace(/(.{2})(.{3})(.{2})/, "$1 $2 $3");
}

function resetCustomTab() {
  verifiedCustomPlate = null;
  document.getElementById("customPlateInput").value = "";
  document.getElementById("availabilityMsg").innerText = "";
  document.getElementById("availabilityMsg").className = "availability-msg";
  document.getElementById("buyCustomBtn").disabled = true;
}

function handleAvailabilityResult(result) {
  const msgBox = document.getElementById("availabilityMsg");
  const buyBtn = document.getElementById("buyCustomBtn");

  if (result.reason === "invalid") {
    msgBox.innerText = "Neispravan format (samo slova/brojevi, 4-8 znakova)";
    msgBox.className = "availability-msg msg-error";
    buyBtn.disabled = true;
    return;
  }

  if (result.available) {
    msgBox.innerText = "✓ Tablica je dostupna!";
    msgBox.className = "availability-msg msg-success";
    buyBtn.disabled = false;
    verifiedCustomPlate = result.plate;
  } else {
    msgBox.innerText = "✕ Tablica je vec zauzeta";
    msgBox.className = "availability-msg msg-error";
    buyBtn.disabled = true;
    verifiedCustomPlate = null;
  }
}

/* ---------- POST HELPER ---------- */
function post(endpoint, data) {
  return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data || {}),
  });
}

function GetParentResourceName() {
  return window.GetParentResourceName
    ? window.GetParentResourceName()
    : "kt-kt-vehicle-registration";
}

/* ---------- STATIC EVENT LISTENERS ---------- */
document.getElementById("closeBtn").addEventListener("click", () => {
  post("close");
  app.classList.add("hidden");
});

document.getElementById("registerBtn").addEventListener("click", () => {
  post("register", { plate: currentPlate, model: currentModel });
  app.classList.add("hidden");
});

document.getElementById("renewBtn").addEventListener("click", () => {
  post("renew", { plate: currentPlate });
  app.classList.add("hidden");
});

document
  .getElementById("checkAvailabilityBtn")
  .addEventListener("click", () => {
    const input = document
      .getElementById("customPlateInput")
      .value.trim()
      .toUpperCase();
    if (!input) return;
    post("checkPlateAvailability", { plate: input });
  });

document.getElementById("buyCustomBtn").addEventListener("click", () => {
  if (!verifiedCustomPlate) return;
  post("buyPersonalized", {
    oldPlate: currentPlate,
    plate: verifiedCustomPlate,
    model: currentModel,
  });
});

document.getElementById("customPlateInput").addEventListener("input", (e) => {
  e.target.value = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, "");
  document.getElementById("customPlatePreview").innerText = formatPlate(
    e.target.value.padEnd(7, "·"),
  );
  document.getElementById("buyCustomBtn").disabled = true;
  document.getElementById("availabilityMsg").innerText = "";
});

/* ---------- TABS ---------- */
document.querySelectorAll(".tab-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    document
      .querySelectorAll(".tab-btn")
      .forEach((b) => b.classList.remove("active"));
    document
      .querySelectorAll(".tab-content")
      .forEach((c) => c.classList.remove("active"));

    btn.classList.add("active");
    document.getElementById("tab-" + btn.dataset.tab).classList.add("active");
  });
});

/* ---------- ESC TO CLOSE ---------- */
document.addEventListener("keyup", (e) => {
  if (e.key === "Escape") {
    post("close");
    app.classList.add("hidden");
  }
});
