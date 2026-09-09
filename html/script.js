const app = document.getElementById("app");
let currentPlate = "";
let currentModel = "";
let verifiedCustomPlate = null;

/* ================== HELPERI ================== */

function getResourceName() {
  return typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "kt-vehicle-registration";
}

function post(endpoint, data) {
  return fetch(`https://${getResourceName()}/${endpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data || {}),
  });
}

function formatPlate(plate) {
  return plate.replace(/(.{2})(.{3})(.{2})/, "$1 $2 $3");
}

function getDaysLeft(expiresAt) {
  const expires = new Date(expiresAt);
  const now = new Date();
  return Math.ceil((expires - now) / (1000 * 60 * 60 * 24));
}

function setBadge(el, type, text) {
  el.className = `badge badge-${type}`;
  el.innerHTML = `<span class="badge-dot"></span>${text}`;
}

function showToast(message, type = "success") {
  const container = document.getElementById("toastContainer");
  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  toast.innerHTML = `<span class="toast-icon">${type === "success" ? "✓" : "✕"}</span><span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => toast.remove(), 3000);
}

/* ================== NUI MESSAGE HANDLER ================== */

window.addEventListener("message", (event) => {
  const msg = event.data;

  if (msg.action === "open") openOwnerView(msg);
  if (msg.action === "openLookup") openLookupView(msg);
  if (msg.action === "plateAvailability") handleAvailabilityResult(msg.result);
  if (msg.action === "toast") showToast(msg.message, msg.toastType);

  if (msg.action === "personalizedSuccess") {
    const plateText = document.querySelector("#plateDisplay .plate-text");
    plateText.innerText = formatPlate(msg.plate);
    document.getElementById("plateDisplay").classList.add("premium");
    app.classList.add("hidden");
  }

  if (msg.action === "forceClose") {
    app.classList.add("hidden");
  }
});

/* ================== OWNER VIEW (registracija/obnova) ================== */

function openOwnerView(msg) {
  currentPlate = msg.plate;
  currentModel = msg.model;

  document.getElementById("headerTitle").innerText = "Registracija Vozila";
  document.getElementById("headerIconText").innerText = "🚗";

  document.getElementById("mainTabs").classList.remove("hidden");

  document.querySelectorAll(".tab-btn").forEach((btn, i) => {
    btn.classList.toggle("active", i === 0);
  });
  document
    .querySelectorAll(".tab-content")
    .forEach((c) => c.classList.remove("active"));
  document.getElementById("tab-main").classList.add("active");

  document.querySelector("#plateDisplay .plate-text").innerText = formatPlate(
    msg.plate,
  );
  document.getElementById("modelText").innerText = msg.model;
  document.querySelector("#customPlatePreview .plate-text").innerText =
    formatPlate(msg.plate);

  const plateDisplay = document.getElementById("plateDisplay");
  const badge = document.getElementById("statusBadge");
  const daysLeft = document.getElementById("daysLeft");
  const registerBtn = document.getElementById("registerBtn");
  const renewBtn = document.getElementById("renewBtn");
  const ownerName = document.getElementById("ownerName");
  const vehicleId = document.getElementById("vehicleId");

  plateDisplay.classList.toggle(
    "premium",
    !!(msg.data && msg.data.personalized),
  );

  if (!msg.data) {
    setBadge(badge, "none", "Nije registrovano");
    daysLeft.innerText = "";
    registerBtn.classList.remove("hidden");
    renewBtn.classList.add("hidden");
    ownerName.innerText = "—";
    vehicleId.innerText = "—";
  } else {
    const diffDays = getDaysLeft(msg.data.expires_at);
    setBadge(
      badge,
      diffDays > 0 ? "active" : "expired",
      diffDays > 0 ? "Aktivna" : "Istekla",
    );
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

function resetCustomTab() {
  verifiedCustomPlate = null;
  document.getElementById("customPlateInput").value = "";
  document.getElementById("inputCounter").innerText = "0/8";
  document.getElementById("availabilityMsg").innerText = "";
  document.getElementById("availabilityMsg").className = "availability-msg";
  document.getElementById("buyCustomBtn").disabled = true;
}

function handleAvailabilityResult(result) {
  const msgBox = document.getElementById("availabilityMsg");
  const buyBtn = document.getElementById("buyCustomBtn");

  if (result.reason === "invalid") {
    msgBox.innerText = "Neispravan format (4-8 znakova, samo slova/brojevi)";
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

/* ================== LOOKUP VIEW (provera - svi) ================== */

function openLookupView(msg) {
  document.getElementById("headerTitle").innerText = "Provera Registracije";
  document.getElementById("headerIconText").innerText = "🔍";
  document.getElementById("modelText").innerText = msg.model;

  document.getElementById("mainTabs").classList.add("hidden");
  document
    .querySelectorAll(".tab-content")
    .forEach((c) => c.classList.remove("active"));
  document.getElementById("tab-lookup").classList.add("active");

  const plateDisplay = document.getElementById("lookupPlateDisplay");
  document.querySelector("#lookupPlateDisplay .plate-text").innerText =
    formatPlate(msg.plate);

  const badge = document.getElementById("lookupStatusBadge");
  const daysLeft = document.getElementById("lookupDaysLeft");
  const daysBox = document.getElementById("lookupDaysBox");
  const personalizedRow = document.getElementById("lookupPersonalizedRow");

  document.getElementById("lookupModel").innerText = msg.model;
  personalizedRow.innerHTML = "";
  plateDisplay.classList.toggle(
    "premium",
    !!(msg.data && msg.data.personalized),
  );

  if (!msg.data) {
    setBadge(badge, "none", "Nije registrovano");
    daysLeft.innerText = "";
    daysBox.innerText = "—";
    document.getElementById("lookupRegisteredDate").innerText = "—";
  } else {
    const diffDays = getDaysLeft(msg.data.expires_at);
    setBadge(
      badge,
      diffDays > 0 ? "active" : "expired",
      diffDays > 0 ? "Aktivna" : "Istekla",
    );
    daysLeft.innerText =
      diffDays > 0 ? `${diffDays} dana preostalo` : "Isteklo";
    daysBox.innerText = diffDays > 0 ? `${diffDays} dana` : "Isteklo";

    const regDate = new Date(msg.data.registered_at);
    document.getElementById("lookupRegisteredDate").innerText =
      regDate.toLocaleDateString("sr-RS");

    if (msg.data.personalized) {
      personalizedRow.innerHTML =
        '<span class="badge-gold-tag">★ Personalizovana tablica</span>';
    }
  }

  app.classList.remove("hidden");
}

/* ================== STATIC LISTENERS ================== */

document.getElementById("closeBtn").addEventListener("click", () => {
  post("close");
  post("closeLookup");
  app.classList.add("hidden");
});

document.getElementById("closeLookupBtn").addEventListener("click", () => {
  post("closeLookup");
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
  document.getElementById("inputCounter").innerText =
    `${e.target.value.length}/8`;
  document.querySelector("#customPlatePreview .plate-text").innerText =
    formatPlate(e.target.value.padEnd(7, "·"));
  document.getElementById("buyCustomBtn").disabled = true;
  document.getElementById("availabilityMsg").innerText = "";
});

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

document.addEventListener("keyup", (e) => {
  if (e.key === "Escape") {
    post("close");
    post("closeLookup");
    app.classList.add("hidden");
  }
});
