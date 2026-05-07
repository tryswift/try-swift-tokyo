// student.tryswift.jp client-side glue.
//
// The static HTML shells render at build time with empty placeholder
// elements; this script fetches dynamic data from api.tryswift.jp and fills
// them in on page load. It also sets up form helpers for the apply page
// (educational-email hint, conditional travel/accommodation sections,
// total cost recalculation, travel-cost lookup) and wires the logout button.

(function () {
  "use strict";

  const apiBaseURL = document
    .querySelector('meta[name="scholarship-api-base-url"]')
    ?.getAttribute("content");
  const locale = document
    .querySelector('meta[name="scholarship-locale"]')
    ?.getAttribute("content") || "en";

  const PATH_PREFIX = locale === "ja" ? "/ja" : "";

  if (!apiBaseURL) {
    console.warn("scholarship.js: api base url meta tag missing");
    return;
  }

  const EDU_SUFFIXES = [
    ".ac.jp", ".edu", ".edu.au", ".edu.cn", ".edu.tw", ".edu.hk",
    ".edu.sg", ".edu.my", ".edu.in", ".edu.ph", ".edu.br", ".edu.mx",
    ".edu.co", ".ac.uk", ".ac.kr", ".ac.nz", ".ac.th", ".edu.es",
    ".edu.fr", ".edu.it", ".edu.pl", ".ac.at", ".ac.be",
  ];

  // ---- helpers ---------------------------------------------------------

  function api(path, options) {
    return fetch(apiBaseURL + path, {
      ...options,
      credentials: "include",
      headers: {
        Accept: "application/json",
        ...(options && options.headers),
      },
    });
  }

  function escapeHTML(value) {
    return String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function showFlash(message, kind) {
    const el = document.getElementById("flash");
    if (!el) return;
    el.textContent = message;
    el.classList.remove("hidden");
    if (kind) el.classList.add(kind);
  }

  function setNavAuthState(state) {
    document.querySelectorAll("[data-auth-state]").forEach((el) => {
      const want = el.getAttribute("data-auth-state");
      const visible =
        (state === "signed-out" && want === "signed-out") ||
        (state === "signed-in" && (want === "signed-in")) ||
        (state === "organizer" && (want === "signed-in" || want === "organizer"));
      el.toggleAttribute("hidden", !visible);
    });
  }

  // ---- /me -------------------------------------------------------------

  let currentMe = null;

  async function fetchMe() {
    try {
      const res = await api("/api/v1/scholarship/me");
      if (res.status === 401) {
        currentMe = null;
        setNavAuthState("signed-out");
        return null;
      }
      if (!res.ok) return null;
      const json = await res.json();
      currentMe = json;
      setNavAuthState(json.isOrganizer ? "organizer" : "signed-in");
      return json;
    } catch (e) {
      console.warn("scholarship.js: /me failed", e);
      return null;
    }
  }

  // ---- per-page handlers ----------------------------------------------

  async function handleInfo() {
    try {
      const res = await api("/api/v1/scholarship/info");
      if (!res.ok) return;
      const data = await res.json();
      const info = document.getElementById("conference-info");
      if (info && data.conferenceDisplayName) {
        info.textContent =
          (locale === "ja" ? data.conferenceDisplayName + "の" : "") +
          info.textContent;
      }
      const budgetEl = document.getElementById("budget-summary");
      if (budgetEl && data.budget) {
        const total = data.budget.totalBudget;
        const approved = data.budget.approvedTotal;
        const remaining = data.budget.remaining;
        if (total != null) {
          budgetEl.innerHTML =
            "<dl>" +
            "<dt>Total</dt><dd>¥" + total.toLocaleString() + "</dd>" +
            "<dt>Approved</dt><dd>¥" + approved.toLocaleString() + "</dd>" +
            (remaining != null
              ? "<dt>Remaining</dt><dd>¥" + remaining.toLocaleString() + "</dd>"
              : "") +
            "</dl>";
        }
      }
      const cta = document.getElementById("apply-cta");
      if (cta && currentMe) cta.setAttribute("href", PATH_PREFIX + "/apply");
    } catch (e) {
      console.warn("scholarship.js: /info failed", e);
    }
  }

  function handleApply() {
    if (!currentMe) {
      window.location.href = PATH_PREFIX + "/login";
      return;
    }
    // Pre-fill email and name from the authenticated session.
    const emailInput = document.querySelector("[name='email']");
    const nameInput = document.querySelector("[name='name']");
    if (emailInput && !emailInput.value && currentMe.email) emailInput.value = currentMe.email;
    if (nameInput && !nameInput.value && currentMe.displayName) nameInput.value = currentMe.displayName;

    setupApplyFormBehaviors();
  }

  function setupApplyFormBehaviors() {
    function toggleTravelSections(value) {
      const showTravel = value === "ticket_and_travel";
      const t = document.getElementById("section-travel");
      const a = document.getElementById("section-accommodation");
      if (t) t.classList.toggle("hidden", !showTravel);
      if (a) a.classList.toggle("hidden", !showTravel);
    }
    document.querySelectorAll("[name='support_type']").forEach((el) => {
      el.addEventListener("change", (e) => toggleTravelSections(e.target.value));
      if (el.checked) toggleTravelSections(el.value);
    });

    const emailInput = document.querySelector("[name='email']");
    const hint = document.getElementById("email-domain-hint");
    function checkEmail(value) {
      const at = value.lastIndexOf("@");
      if (at < 0 || !hint) return;
      const domain = value.slice(at).toLowerCase();
      const ok = EDU_SUFFIXES.some((s) => domain.endsWith(s));
      hint.classList.toggle("hidden", ok);
    }
    if (emailInput) {
      emailInput.addEventListener("input", (e) => checkEmail(e.target.value));
      checkEmail(emailInput.value);
    }

    function recalcTotal() {
      const t = Number(document.querySelector("[name='estimated_round_trip_cost']")?.value || 0);
      const a = Number(document.querySelector("[name='estimated_accommodation_cost']")?.value || 0);
      const total = document.querySelector("[name='total_estimated_cost']");
      if (total) total.value = String(t + a);
    }
    document.querySelector("[name='estimated_round_trip_cost']")?.addEventListener("input", recalcTotal);
    document.querySelector("[name='estimated_accommodation_cost']")?.addEventListener("input", recalcTotal);

    document.getElementById("estimate-travel-button")?.addEventListener("click", async () => {
      const cityEl = document.querySelector("[name='origin_city']");
      const out = document.getElementById("travel-estimate-result");
      if (!cityEl || !out) return;
      const city = cityEl.value;
      if (!city) { out.textContent = ""; return; }
      try {
        const res = await api("/api/v1/scholarship/api/travel-cost?from=" + encodeURIComponent(city));
        if (!res.ok) { out.textContent = "—"; return; }
        const data = await res.json();
        const parts = [];
        if (data.bulletTrain != null) parts.push("新幹線 ¥" + data.bulletTrain);
        if (data.airplane != null) parts.push("飛行機 ¥" + data.airplane);
        if (data.bus != null) parts.push("バス ¥" + data.bus);
        if (data.train != null) parts.push("電車 ¥" + data.train);
        out.textContent = parts.length ? parts.join(" / ") : "—";
      } catch (_) {
        out.textContent = "—";
      }
    });
  }

  async function handleMyApplication() {
    if (!currentMe) {
      window.location.href = PATH_PREFIX + "/login";
      return;
    }
    try {
      const res = await api("/api/v1/scholarship/me/application");
      if (res.status === 404) return;
      if (!res.ok) return;
      const app = await res.json();
      const root = document.getElementById("my-application");
      if (root) {
        root.innerHTML =
          "<dl>" +
          "<dt>Status</dt><dd>" + escapeHTML(app.status) + "</dd>" +
          "<dt>Email</dt><dd>" + escapeHTML(app.email) + "</dd>" +
          "<dt>Name</dt><dd>" + escapeHTML(app.name) + "</dd>" +
          "<dt>School</dt><dd>" + escapeHTML(app.schoolAndFaculty) + "</dd>" +
          (app.approvedAmount != null
            ? "<dt>Approved</dt><dd>¥" + app.approvedAmount + "</dd>"
            : "") +
          "</dl>";
      }
      if (app.status === "submitted") {
        document.getElementById("withdraw-form")?.classList.remove("hidden");
      }
    } catch (e) {
      console.warn("scholarship.js: /me/application failed", e);
    }
  }

  async function handleOrganizerList() {
    if (!currentMe || !currentMe.isOrganizer) {
      window.location.href = PATH_PREFIX + "/login";
      return;
    }
    try {
      const res = await api("/api/v1/scholarship/organizer/applications");
      if (!res.ok) return;
      const data = await res.json();
      const tbody = document.getElementById("applications-tbody");
      if (tbody) {
        tbody.innerHTML = data.applications.map((app) => (
          "<tr>" +
          "<td>" + escapeHTML(String(app.id).slice(0, 8)) + "</td>" +
          "<td>" + escapeHTML(app.name) + "</td>" +
          "<td>" + escapeHTML(app.schoolAndFaculty) + "</td>" +
          "<td>" + escapeHTML(app.supportType) + "</td>" +
          "<td>" + escapeHTML(app.status) + "</td>" +
          "<td>" + (app.approvedAmount != null ? "¥" + app.approvedAmount : "—") + "</td>" +
          "<td><a href=\"" + PATH_PREFIX + "/organizer/" + escapeHTML(app.id) + "\">Detail</a></td>" +
          "</tr>"
        )).join("");
      }
      const summary = document.getElementById("budget-summary");
      if (summary && data.budget) {
        const b = data.budget;
        summary.innerHTML =
          "<dl>" +
          "<dt>Total</dt><dd>" + (b.totalBudget != null ? "¥" + b.totalBudget : "—") + "</dd>" +
          "<dt>Approved</dt><dd>¥" + b.approvedTotal + "</dd>" +
          (b.remaining != null ? "<dt>Remaining</dt><dd>¥" + b.remaining + "</dd>" : "") +
          "</dl>";
      }
    } catch (e) {
      console.warn("scholarship.js: organizer list failed", e);
    }
  }

  async function handleOrganizerDetail() {
    if (!currentMe || !currentMe.isOrganizer) {
      window.location.href = PATH_PREFIX + "/login";
      return;
    }
    const segments = window.location.pathname.split("/").filter(Boolean);
    const id = segments[segments.length - 1];
    if (!id) return;
    try {
      const res = await api("/api/v1/scholarship/organizer/applications/" + encodeURIComponent(id));
      if (!res.ok) return;
      const app = await res.json();
      const root = document.getElementById("application-detail");
      if (root) {
        root.innerHTML =
          "<dl>" +
          "<dt>Status</dt><dd>" + escapeHTML(app.status) + "</dd>" +
          "<dt>Email</dt><dd>" + escapeHTML(app.email) + "</dd>" +
          "<dt>Name</dt><dd>" + escapeHTML(app.name) + "</dd>" +
          "<dt>School</dt><dd>" + escapeHTML(app.schoolAndFaculty) + "</dd>" +
          "<dt>Support</dt><dd>" + escapeHTML(app.supportType) + "</dd>" +
          (app.totalEstimatedCost != null ? "<dt>Estimated cost</dt><dd>¥" + app.totalEstimatedCost + "</dd>" : "") +
          (app.desiredSupportAmount != null ? "<dt>Desired</dt><dd>¥" + app.desiredSupportAmount + "</dd>" : "") +
          "</dl>";
      }
      const approve = document.getElementById("approve-form");
      const reject = document.getElementById("reject-form");
      const revert = document.getElementById("revert-form");
      if (approve) {
        approve.classList.remove("hidden");
        approve.action = apiBaseURL + "/api/v1/scholarship/organizer/applications/" + id + "/approve";
        const amt = approve.querySelector("[name='approved_amount']");
        if (amt && app.approvedAmount != null) amt.value = String(app.approvedAmount);
        const notes = approve.querySelector("[name='organizer_notes']");
        if (notes && app.organizerNotes) notes.value = app.organizerNotes;
      }
      if (reject) {
        reject.classList.remove("hidden");
        reject.action = apiBaseURL + "/api/v1/scholarship/organizer/applications/" + id + "/reject";
      }
      if (revert && app.status !== "submitted") {
        revert.classList.remove("hidden");
        revert.action = apiBaseURL + "/api/v1/scholarship/organizer/applications/" + id + "/revert";
      }
    } catch (e) {
      console.warn("scholarship.js: organizer detail failed", e);
    }
  }

  async function handleOrganizerBudget() {
    if (!currentMe || !currentMe.isOrganizer) {
      window.location.href = PATH_PREFIX + "/login";
      return;
    }
    try {
      const res = await api("/api/v1/scholarship/organizer/budget");
      if (!res.ok) return;
      const data = await res.json();
      const summary = document.getElementById("budget-summary");
      if (summary && data.summary) {
        const s = data.summary;
        summary.innerHTML =
          "<dl>" +
          "<dt>Approved</dt><dd>¥" + s.approvedTotal + "</dd>" +
          (s.remaining != null ? "<dt>Remaining</dt><dd>¥" + s.remaining + "</dd>" : "") +
          "</dl>";
      }
      const form = document.getElementById("budget-form");
      if (form && data.budget) {
        const total = form.querySelector("[name='total_budget']");
        const notes = form.querySelector("[name='notes']");
        if (total) total.value = String(data.budget.totalBudget);
        if (notes && data.budget.notes) notes.value = data.budget.notes;
      }
    } catch (e) {
      console.warn("scholarship.js: organizer budget failed", e);
    }
  }

  function setupLogout() {
    const btn = document.getElementById("nav-logout-button");
    if (!btn) return;
    btn.addEventListener("click", async () => {
      try {
        await api("/api/v1/scholarship/logout", { method: "POST" });
      } catch (_) {}
      window.location.href = PATH_PREFIX + "/";
    });
  }

  // ---- bootstrap -------------------------------------------------------

  document.addEventListener("DOMContentLoaded", async () => {
    await fetchMe();
    setupLogout();
    const page = document.body.getAttribute("data-page");
    switch (page) {
      case "info": handleInfo(); break;
      case "apply": handleApply(); break;
      case "my-application": handleMyApplication(); break;
      case "organizer-list": handleOrganizerList(); break;
      case "organizer-detail": handleOrganizerDetail(); break;
      case "organizer-budget": handleOrganizerBudget(); break;
      default: break;
    }
  });
})();
