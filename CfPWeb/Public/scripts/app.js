(function () {
  var state = {
    user: null,
    openConferences: [],
    conferences: [],
    workshops: [],
    workshopVerifySession: null,
    myProposals: [],
    feedbackGroups: [],
    organizerProposals: [],
    organizerSlots: [],
    organizerWorkshops: [],
    organizerWorkshopApplications: [],
    organizerWorkshopResults: []
  };

  function apiBaseURL() {
    var meta = document.querySelector('meta[name="cfp-api-base-url"]');
    return meta ? meta.content : "https://api.tryswift.jp";
  }

  function currentPagePath() {
    return window.location.pathname + window.location.search + window.location.hash;
  }

  function normalizedPathname() {
    var path = window.location.pathname || "/";
    if (path.indexOf("/ja/") === 0) {
      path = path.slice(3) || "/";
    } else if (path === "/ja") {
      path = "/";
    }
    if (path.length > 1 && path.charAt(path.length - 1) === "/") {
      path = path.slice(0, -1);
    }
    return path;
  }

  async function apiRequest(path, options) {
    var requestOptions = Object.assign(
      {
        credentials: "include",
        headers: {
          Accept: "application/json"
        }
      },
      options || {}
    );

    if (requestOptions.body && !(requestOptions.body instanceof FormData) && !requestOptions.headers["Content-Type"]) {
      requestOptions.headers["Content-Type"] = "application/json";
    }

    var response = await fetch(apiBaseURL() + path, requestOptions);
    var contentType = response.headers.get("content-type") || "";
    var payload = null;

    if (contentType.indexOf("application/json") >= 0) {
      payload = await response.json();
    } else {
      payload = await response.text();
    }

    if (!response.ok) {
      var error = new Error(extractErrorMessage(payload, response.status));
      error.status = response.status;
      error.payload = payload;
      throw error;
    }

    return payload;
  }

  function extractErrorMessage(payload, status) {
    if (payload && typeof payload === "object") {
      if (typeof payload.reason === "string" && payload.reason.length > 0) return payload.reason;
      if (typeof payload.error === "string" && payload.error.length > 0) return payload.error;
      if (typeof payload.message === "string" && payload.message.length > 0) return payload.message;
    }

    if (typeof payload === "string" && payload.trim().length > 0) {
      return payload.trim();
    }

    if (status === 401) return "You need to sign in to continue.";
    if (status === 403) return "You do not have permission to do that.";
    return "Request failed (" + status + ").";
  }

  function showStatus(id, message, tone) {
    var node = document.getElementById(id);
    if (!node) return;

    if (!message) {
      node.hidden = true;
      node.textContent = "";
      node.classList.remove("error", "success");
      return;
    }

    node.hidden = false;
    node.textContent = message;
    node.classList.remove("error", "success");
    if (tone) {
      node.classList.add(tone);
    }
  }

  function updateAuthState(user) {
    var authStatus = document.getElementById("auth-status");
    var loginButton = document.getElementById("login-button");
    var submitLoginButton = document.getElementById("submit-login-button");
    var logoutButton = document.getElementById("logout-button");
    var submitAuthCard = document.querySelector(".submit-auth-card");
    var submitFormCard = document.getElementById("submit-form-card");

    updatePageCopy(user);

    if (user) {
      if (authStatus) {
        authStatus.textContent = "Signed in as " + user.username + " (" + user.role + ")";
      }
      if (loginButton) loginButton.hidden = true;
      if (submitLoginButton) submitLoginButton.hidden = true;
      if (submitAuthCard) submitAuthCard.hidden = true;
      if (submitFormCard) submitFormCard.hidden = false;
      if (logoutButton) logoutButton.hidden = false;
    } else {
      if (authStatus) {
        authStatus.textContent = "Not signed in";
      }
      if (loginButton) loginButton.hidden = false;
      if (submitLoginButton) submitLoginButton.hidden = false;
      if (submitAuthCard) submitAuthCard.hidden = false;
      if (submitFormCard) submitFormCard.hidden = true;
      if (logoutButton) logoutButton.hidden = true;
    }
  }

  function updatePageCopy(user) {
    var description = document.getElementById("page-description");
    var detailCopy = document.getElementById("page-detail-copy");
    [description, detailCopy].forEach(function (node) {
      if (!node) return;
      var signedInCopy = node.getAttribute("data-signed-in-copy");
      var signedOutCopy = node.getAttribute("data-signed-out-copy");
      var nextCopy = user ? signedInCopy : signedOutCopy;
      if (nextCopy) {
        node.textContent = nextCopy;
      }
    });
  }

  function wireLogin() {
    var buttons = document.querySelectorAll('[data-login-button], #login-button');
    if (!buttons.length) return;

    buttons.forEach(function (button) {
      button.addEventListener("click", function () {
        var returnTo = window.location.origin + currentPagePath();
        window.location.href = apiBaseURL() + "/api/v1/auth/github?returnTo=" + encodeURIComponent(returnTo);
      });
    });
  }

  function wireLogout() {
    var button = document.getElementById("logout-button");
    if (!button) return;

    button.addEventListener("click", async function () {
      try {
        await apiRequest("/api/v1/auth/logout", { method: "POST" });
        window.location.reload();
      } catch (error) {
        console.error(error);
      }
    });
  }

  function toOptionsMarkup(items, placeholder, valueKey, labelKey) {
    var html = "";
    if (placeholder) {
      html += '<option value="">' + escapeHTML(placeholder) + "</option>";
    }
    items.forEach(function (item) {
      html += '<option value="' + escapeHTML(String(item[valueKey] || "")) + '">';
      html += escapeHTML(String(item[labelKey] || ""));
      html += "</option>";
    });
    return html;
  }

  function populateSelect(id, items, placeholder, valueKey, labelKey) {
    var select = document.getElementById(id);
    if (!select) return;
    var previous = select.value;
    select.innerHTML = toOptionsMarkup(items, placeholder, valueKey, labelKey);
    if (previous && items.some(function (item) { return String(item[valueKey]) === previous; })) {
      select.value = previous;
    } else if (!placeholder && items.length > 0) {
      select.value = String(items[0][valueKey]);
    }
  }

  async function loadOpenConferences() {
    state.openConferences = await apiRequest("/api/v1/conferences/open");
    return state.openConferences;
  }

  async function loadAllConferences() {
    state.conferences = await apiRequest("/api/v1/conferences");
    return state.conferences;
  }

  function prefillSpeakerFields(form, user) {
    if (!form || !user) return;
    if (form.elements.speakerName && !form.elements.speakerName.value && user.displayName) {
      form.elements.speakerName.value = user.displayName;
    }
    if (form.elements.speakerEmail && !form.elements.speakerEmail.value && user.email) {
      form.elements.speakerEmail.value = user.email;
    }
    if (form.elements.bio && !form.elements.bio.value && user.bio) {
      form.elements.bio.value = user.bio;
    }
    if (form.elements.iconURL && !form.elements.iconURL.value && user.avatarURL) {
      form.elements.iconURL.value = user.avatarURL;
    }
    updateAvatarPreview(form);
  }

  function updateAvatarPreview(form) {
    if (!form || !form.elements.iconURL) return;
    var image = document.getElementById("submit-avatar-image");
    if (!image) return;

    var value = (form.elements.iconURL.value || "").trim();
    image.src = value || "/images/riko.png";
  }

  function readFormJSON(form, allowedKeys) {
    var result = {};
    allowedKeys.forEach(function (key) {
      if (!form.elements[key]) return;
      var raw = form.elements[key].value;
      if (typeof raw !== "string") return;
      var trimmed = raw.trim();
      if (trimmed.length > 0) {
        result[key] = trimmed;
      }
    });
    return result;
  }

  function fieldValue(form, name) {
    if (!form || !form.elements[name]) return "";
    return String(form.elements[name].value || "").trim();
  }

  function checkedFacilities(form) {
    var facilities = [];
    if (form.elements.workshopFacilityProjector && form.elements.workshopFacilityProjector.checked) facilities.push("projector");
    if (form.elements.workshopFacilityMicrophone && form.elements.workshopFacilityMicrophone.checked) facilities.push("microphone");
    if (form.elements.workshopFacilityWhiteboard && form.elements.workshopFacilityWhiteboard.checked) facilities.push("whiteboard");
    if (form.elements.workshopFacilityPowerStrips && form.elements.workshopFacilityPowerStrips.checked) facilities.push("power_strips");
    return facilities;
  }

  function readCoInstructors(form, prefixes) {
    return prefixes.map(function (prefix) {
      var name = fieldValue(form, prefix + "Name");
      var email = fieldValue(form, prefix + "Email");
      var githubUsername = fieldValue(form, prefix + "GithubUsername");
      var bio = fieldValue(form, prefix + "Bio");
      var sns = fieldValue(form, prefix + "Sns");
      var iconURL = fieldValue(form, prefix + "IconURL");

      if (!name && !email && !githubUsername && !bio && !sns && !iconURL) {
        return null;
      }

      return {
        name: name,
        email: email,
        githubUsername: githubUsername,
        bio: bio,
        sns: sns || null,
        iconURL: iconURL || null
      };
    }).filter(Boolean);
  }

  function readWorkshopPayload(form, options) {
    var workshopDetails = {
      language: fieldValue(form, "workshopLanguage") || "english",
      numberOfTutors: Number(fieldValue(form, "workshopNumberOfTutors") || "1"),
      keyTakeaways: fieldValue(form, "workshopKeyTakeaways"),
      prerequisites: fieldValue(form, "workshopPrerequisites") || null,
      agendaSchedule: fieldValue(form, "workshopAgendaSchedule"),
      participantRequirements: fieldValue(form, "workshopParticipantRequirements"),
      requiredSoftware: fieldValue(form, "workshopRequiredSoftware") || null,
      networkRequirements: fieldValue(form, "workshopNetworkRequirements"),
      requiredFacilities: checkedFacilities(form),
      facilityOther: fieldValue(form, "workshopFacilityOther") || null,
      motivation: fieldValue(form, "workshopMotivation"),
      uniqueness: fieldValue(form, "workshopUniqueness"),
      potentialRisks: fieldValue(form, "workshopPotentialRisks") || null
    };

    var result = {
      workshopDetails: workshopDetails,
      coInstructors: readCoInstructors(form, options.coInstructorPrefixes || [])
    };

    if (options.includeJapaneseFields) {
      result.workshopDetailsJA = {
        keyTakeaways: fieldValue(form, "workshopKeyTakeawaysJa") || null,
        prerequisites: fieldValue(form, "workshopPrerequisitesJa") || null,
        agendaSchedule: fieldValue(form, "workshopAgendaScheduleJa") || null,
        participantRequirements: fieldValue(form, "workshopParticipantRequirementsJa") || null,
        requiredSoftware: fieldValue(form, "workshopRequiredSoftwareJa") || null,
        networkRequirements: fieldValue(form, "workshopNetworkRequirementsJa") || null
      };
    }

    return result;
  }

  function setFacilityCheckboxes(form, values) {
    var selected = Array.isArray(values) ? values : [];
    if (form.elements.workshopFacilityProjector) form.elements.workshopFacilityProjector.checked = selected.indexOf("projector") >= 0;
    if (form.elements.workshopFacilityMicrophone) form.elements.workshopFacilityMicrophone.checked = selected.indexOf("microphone") >= 0;
    if (form.elements.workshopFacilityWhiteboard) form.elements.workshopFacilityWhiteboard.checked = selected.indexOf("whiteboard") >= 0;
    if (form.elements.workshopFacilityPowerStrips) form.elements.workshopFacilityPowerStrips.checked = selected.indexOf("power_strips") >= 0;
  }

  function setCoInstructorFields(form, prefixes, values) {
    prefixes.forEach(function (prefix, index) {
      var item = values && values[index] ? values[index] : null;
      if (form.elements[prefix + "Name"]) form.elements[prefix + "Name"].value = item ? (item.name || "") : "";
      if (form.elements[prefix + "Email"]) form.elements[prefix + "Email"].value = item ? (item.email || "") : "";
      if (form.elements[prefix + "GithubUsername"]) form.elements[prefix + "GithubUsername"].value = item ? (item.githubUsername || "") : "";
      if (form.elements[prefix + "Bio"]) form.elements[prefix + "Bio"].value = item ? (item.bio || "") : "";
      if (form.elements[prefix + "Sns"]) form.elements[prefix + "Sns"].value = item ? (item.sns || "") : "";
      if (form.elements[prefix + "IconURL"]) form.elements[prefix + "IconURL"].value = item ? (item.iconURL || "") : "";
    });
  }

  function populateWorkshopFields(form, workshopDetails, workshopDetailsJA, coInstructors, options) {
    var details = workshopDetails || {};
    if (form.elements.workshopLanguage) form.elements.workshopLanguage.value = details.language || "english";
    if (form.elements.workshopNumberOfTutors) form.elements.workshopNumberOfTutors.value = String(details.numberOfTutors || 1);
    if (form.elements.workshopKeyTakeaways) form.elements.workshopKeyTakeaways.value = details.keyTakeaways || "";
    if (form.elements.workshopPrerequisites) form.elements.workshopPrerequisites.value = details.prerequisites || "";
    if (form.elements.workshopAgendaSchedule) form.elements.workshopAgendaSchedule.value = details.agendaSchedule || "";
    if (form.elements.workshopParticipantRequirements) form.elements.workshopParticipantRequirements.value = details.participantRequirements || "";
    if (form.elements.workshopRequiredSoftware) form.elements.workshopRequiredSoftware.value = details.requiredSoftware || "";
    if (form.elements.workshopNetworkRequirements) form.elements.workshopNetworkRequirements.value = details.networkRequirements || "";
    if (form.elements.workshopFacilityOther) form.elements.workshopFacilityOther.value = details.facilityOther || "";
    if (form.elements.workshopMotivation) form.elements.workshopMotivation.value = details.motivation || "";
    if (form.elements.workshopUniqueness) form.elements.workshopUniqueness.value = details.uniqueness || "";
    if (form.elements.workshopPotentialRisks) form.elements.workshopPotentialRisks.value = details.potentialRisks || "";
    setFacilityCheckboxes(form, details.requiredFacilities);

    if (options.includeJapaneseFields && workshopDetailsJA) {
      if (form.elements.workshopKeyTakeawaysJa) form.elements.workshopKeyTakeawaysJa.value = workshopDetailsJA.keyTakeaways || "";
      if (form.elements.workshopPrerequisitesJa) form.elements.workshopPrerequisitesJa.value = workshopDetailsJA.prerequisites || "";
      if (form.elements.workshopAgendaScheduleJa) form.elements.workshopAgendaScheduleJa.value = workshopDetailsJA.agendaSchedule || "";
      if (form.elements.workshopParticipantRequirementsJa) form.elements.workshopParticipantRequirementsJa.value = workshopDetailsJA.participantRequirements || "";
      if (form.elements.workshopRequiredSoftwareJa) form.elements.workshopRequiredSoftwareJa.value = workshopDetailsJA.requiredSoftware || "";
      if (form.elements.workshopNetworkRequirementsJa) form.elements.workshopNetworkRequirementsJa.value = workshopDetailsJA.networkRequirements || "";
    }

    setCoInstructorFields(form, options.coInstructorPrefixes || [], coInstructors || []);
  }

  function toggleWorkshopSection(form, sectionId, durationValue) {
    var section = document.getElementById(sectionId);
    if (!form || !section) return;
    section.hidden = durationValue !== "workshop";
  }

  function wireWorkshopToggle(form, durationFieldName, sectionId) {
    if (!form || !form.elements[durationFieldName]) return;
    var update = function () {
      toggleWorkshopSection(form, sectionId, form.elements[durationFieldName].value);
    };
    form.elements[durationFieldName].addEventListener("change", update);
    update();
  }

  function escapeHTML(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function truncate(value, length) {
    if (!value) return "";
    if (value.length <= length) return value;
    return value.slice(0, length - 1) + "...";
  }

  function extractMyProposalRouteID() {
    var match = normalizedPathname().match(/^\/my-proposals\/([^/]+)(?:\/edit)?$/);
    return match ? match[1] : null;
  }

  function extractOrganizerProposalRouteID() {
    var match = normalizedPathname().match(/^\/organizer\/proposals\/([^/]+)(?:\/edit)?$/);
    return match ? match[1] : null;
  }

  function renderWorkshopChoiceOptions(items, selectedValue) {
    var html = '<option value="">Skip</option>';
    items.forEach(function (item) {
      var selected = selectedValue && String(item.id) === String(selectedValue) ? ' selected="selected"' : "";
      html += '<option value="' + escapeHTML(item.id) + '"' + selected + ">";
      html += escapeHTML(item.title + " - " + item.speakerName);
      html += "</option>";
    });
    return html;
  }

  function currentLanguage() {
    var lang = (document.documentElement.lang || "en").toLowerCase();
    return lang.indexOf("ja") === 0 ? "ja" : "en";
  }

  function localizedCopy(english, japanese) {
    return currentLanguage() === "ja" ? japanese : english;
  }

  function workshopLanguageLabel(language) {
    var pageLanguage = currentLanguage();

    if (pageLanguage === "ja") {
      if (language === "english") return "英語";
      if (language === "japanese") return "日本語";
      if (language === "bilingual") return "バイリンガル";
      if (language === "other") return "その他";
      return "未設定";
    }

    if (language === "english") return "English";
    if (language === "japanese") return "Japanese";
    if (language === "bilingual") return "Bilingual";
    if (language === "other") return "Other";
    return "Language not set";
  }

  function capacityLabel() {
    return currentLanguage() === "ja" ? "定員" : "Capacity";
  }

  function speakerAvatarURL(workshop) {
    if (workshop.iconURL) return workshop.iconURL;
    if (workshop.githubUsername) return "https://github.com/" + workshop.githubUsername + ".png?size=240";
    return "/images/riko.png";
  }

  function renderTextBlocks(text) {
    if (!text) return "<p>N/A</p>";

    return String(text)
      .split(/\n\s*\n/)
      .map(function (block) {
        return "<p>" + escapeHTML(block.trim()).replace(/\n/g, "<br>") + "</p>";
      })
      .join("");
  }

  function renderValueBlock(text) {
    if (!text) return "<p>N/A</p>";
    return "<p>" + escapeHTML(String(text)) + "</p>";
  }

  function renderCoInstructors(items) {
    if (!items || !items.length) return "";

    return (
      '<div class="workshop-subsection">' +
        "<h6>Co-Instructors</h6>" +
        items.map(function (item) {
          var links = [];
          if (item.githubUsername) {
            links.push('<a href="https://github.com/' + encodeURIComponent(item.githubUsername) + '" target="_blank" rel="noreferrer">GitHub ' + escapeHTML(item.githubUsername) + "</a>");
          }
          if (item.sns) {
            links.push('<a href="' + escapeHTML(item.sns) + '" target="_blank" rel="noreferrer">' + escapeHTML(item.sns) + "</a>");
          }

          return (
            '<div class="co-instructor-card">' +
              "<h6>" + escapeHTML(item.name) + "</h6>" +
              (links.length ? '<p class="co-instructor-links">' + links.join(" ") + "</p>" : "") +
              "<p>" + escapeHTML(item.bio || "") + "</p>" +
            "</div>"
          );
        }).join("") +
      "</div>"
    );
  }

  function renderWorkshopDetailContent(workshop) {
    var details = workshop.workshopDetails || {};

    return (
      '<article class="workshop-detail-card" id="workshop-' + escapeHTML(workshop.registrationID) + '">' +
        "<h5>" + escapeHTML(workshop.title) + "</h5>" +
        '<div class="workshop-detail-speaker">' +
          '<img class="workshop-avatar" src="' + escapeHTML(speakerAvatarURL(workshop)) + '" alt="' + escapeHTML(workshop.speakerName) + '">' +
          '<div class="workshop-speaker-copy">' +
            "<h6>" + escapeHTML(workshop.speakerName) + "</h6>" +
            renderTextBlocks(workshop.bio) +
            '<p class="workshop-language-label">' + escapeHTML(workshopLanguageLabel(workshop.workshopLanguage)) + "</p>" +
          "</div>" +
        "</div>" +
        '<div class="workshop-subsection"><h6>Description</h6>' + renderTextBlocks(workshop.talkDetail || workshop.abstract) + "</div>" +
        '<div class="workshop-subsection"><h6>Key Takeaways</h6>' + renderValueBlock(details.keyTakeaways) + "</div>" +
        (details.prerequisites ? '<div class="workshop-subsection"><h6>Prerequisites</h6>' + renderValueBlock(details.prerequisites) + "</div>" : "") +
        '<div class="workshop-subsection"><h6>Agenda / Schedule</h6>' + renderValueBlock(details.agendaSchedule) + "</div>" +
        '<div class="workshop-subsection"><h6>What to Bring</h6>' + renderValueBlock(details.participantRequirements) + "</div>" +
        (details.requiredSoftware ? '<div class="workshop-subsection"><h6>Required Software</h6>' + renderValueBlock(details.requiredSoftware) + "</div>" : "") +
        '<div class="workshop-subsection"><h6>Network Requirements</h6>' + renderValueBlock(details.networkRequirements) + "</div>" +
        renderCoInstructors(workshop.coInstructors) +
      "</article>"
    );
  }

  function openWorkshopModal(registrationID) {
    var workshop = state.workshops.find(function (item) {
      return String(item.registrationID) === String(registrationID);
    });
    var modal = document.getElementById("workshop-modal");
    var body = document.getElementById("workshop-modal-body");
    if (!workshop || !modal || !body) return;

    body.innerHTML = renderWorkshopDetailContent(workshop);
    modal.hidden = false;
    document.body.classList.add("modal-open");
  }

  function closeWorkshopModal() {
    var modal = document.getElementById("workshop-modal");
    var body = document.getElementById("workshop-modal-body");
    if (!modal) return;

    modal.hidden = true;
    if (body) body.innerHTML = "";
    document.body.classList.remove("modal-open");
  }

  function wireWorkshopModal() {
    var list = document.getElementById("workshop-list");
    var modal = document.getElementById("workshop-modal");
    if (!list || !modal) return;

    list.addEventListener("click", function (event) {
      var trigger = event.target.closest("[data-workshop-open]");
      if (!trigger) return;
      openWorkshopModal(trigger.getAttribute("data-workshop-open"));
    });

    modal.addEventListener("click", function (event) {
      if (event.target.closest("[data-workshop-modal-close]")) {
        closeWorkshopModal();
      }
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        closeWorkshopModal();
      }
    });
  }

  function renderWorkshops() {
    var list = document.getElementById("workshop-list");
    if (!list) return;

    if (!state.workshops.length) {
      list.innerHTML = '<div class="empty-state"><p>No accepted workshops are available right now.</p></div>';
      return;
    }

    list.innerHTML = state.workshops.map(function (workshop) {
      var capacity = workshop.capacity || workshop.remainingCapacity;

      return (
        '<article class="proposal-card workshop-card">' +
          '<button type="button" class="workshop-summary-link" data-workshop-open="' + escapeHTML(workshop.registrationID) + '">' +
            "<h4>" + escapeHTML(workshop.title) + "</h4>" +
            '<p class="workshop-speaker">' + escapeHTML(workshop.speakerName || "") + "</p>" +
            '<p class="proposal-summary">' + escapeHTML(truncate(workshop.abstract, 320)) + "</p>" +
            '<div class="proposal-meta workshop-summary-meta">' +
              '<span class="pill capacity-pill">' + escapeHTML(capacityLabel()) + ': ' + escapeHTML(String(capacity || 0)) + "</span>" +
              '<span class="pill language-pill">' + escapeHTML(workshopLanguageLabel(workshop.workshopLanguage)) + "</span>" +
            "</div>" +
            '<span class="workshop-summary-action">' + escapeHTML(localizedCopy("View details", "詳細を見る")) + "</span>" +
          "</button>" +
        "</article>"
      );
    }).join("");
  }

  function renderWorkshopStatusResult(application) {
    var container = document.getElementById("workshop-status-result");
    if (!container) return;

    if (!application) {
      container.innerHTML = '<p>No workshop application found for that email.</p>';
      return;
    }

    var actions = "";
    if (application.canModify && application.deleteToken) {
      actions += '<button type="button" class="button danger" data-workshop-delete-token="' + escapeHTML(application.deleteToken) + '">Delete Pending Application</button>';
    }
    if (application.cancelToken) {
      actions += '<button type="button" class="button danger" data-workshop-cancel-token="' + escapeHTML(application.cancelToken) + '">Cancel Participation</button>';
    }

    container.innerHTML = (
      '<div class="proposal-card workshop-status-card">' +
        "<h4>" + escapeHTML(application.applicantName) + "</h4>" +
        '<div class="proposal-meta">' +
          '<span class="pill">' + escapeHTML(application.status) + "</span>" +
          '<span class="pill">' + escapeHTML(application.email) + "</span>" +
        "</div>" +
        '<div class="plain-list">' +
          '<p><strong>First choice:</strong> ' + escapeHTML(application.firstChoice) + "</p>" +
          (application.secondChoice ? '<p><strong>Second choice:</strong> ' + escapeHTML(application.secondChoice) + "</p>" : "") +
          (application.thirdChoice ? '<p><strong>Third choice:</strong> ' + escapeHTML(application.thirdChoice) + "</p>" : "") +
          (application.assignedWorkshop ? '<p><strong>Assigned workshop:</strong> ' + escapeHTML(application.assignedWorkshop) + "</p>" : "") +
        "</div>" +
        (actions ? '<div class="form-actions">' + actions + "</div>" : "") +
      "</div>"
    );
  }

  function renderMyProposals() {
    var list = document.getElementById("my-proposals-list");
    var empty = document.getElementById("my-proposals-empty");
    if (!list || !empty) return;

    if (!state.user) {
      list.innerHTML = "";
      empty.hidden = false;
      empty.innerHTML = "<p>Sign in to view and edit your proposals.</p>";
      return;
    }

    if (!state.myProposals.length) {
      list.innerHTML = "";
      empty.hidden = false;
      empty.innerHTML = "<p>No proposals found yet. You can submit one from the Submit page.</p>";
      return;
    }

    empty.hidden = true;
    list.innerHTML = state.myProposals.map(function (proposal) {
      return (
        '<article class="proposal-card">' +
          "<h4>" + escapeHTML(proposal.title) + "</h4>" +
          '<div class="proposal-meta">' +
            '<span class="pill">' + escapeHTML(proposal.conferenceDisplayName) + "</span>" +
            '<span class="pill">' + escapeHTML(proposal.talkDuration) + "</span>" +
            '<span class="pill">' + escapeHTML(proposal.status) + "</span>" +
          "</div>" +
          '<p class="proposal-summary">' + escapeHTML(truncate(proposal.abstract, 220)) + "</p>" +
          '<div class="proposal-actions">' +
            '<button type="button" class="button neutral" data-edit-proposal="' + escapeHTML(proposal.id) + '">Edit</button>' +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  function loadProposalIntoEditor(proposalID) {
    var proposal = state.myProposals.find(function (item) { return item.id === proposalID; });
    var form = document.getElementById("proposal-editor-form");
    var placeholder = document.getElementById("proposal-editor-placeholder");
    if (!proposal || !form || !placeholder) return;

    form.hidden = false;
    placeholder.hidden = true;

    form.elements.proposalID.value = proposal.id;
    form.elements.title.value = proposal.title || "";
    form.elements.abstract.value = proposal.abstract || "";
    form.elements.talkDetail.value = proposal.talkDetail || "";
    form.elements.talkDuration.value = proposal.talkDuration || "20min";
    form.elements.speakerName.value = proposal.speakerName || "";
    form.elements.speakerEmail.value = proposal.speakerEmail || "";
    form.elements.bio.value = proposal.bio || "";
    form.elements.iconURL.value = proposal.iconURL || "";
    form.elements.notes.value = proposal.notes || "";
    populateWorkshopFields(form, proposal.workshopDetails, null, proposal.coInstructors, {
      coInstructorPrefixes: ["speaker-edit-co1", "speaker-edit-co2"],
      includeJapaneseFields: false
    });
    toggleWorkshopSection(form, "speaker-edit-workshop-section", form.elements.talkDuration.value);
  }

  function renderOrganizerProposals() {
    var list = document.getElementById("organizer-proposals");
    if (!list) return;

    if (!state.user) {
      list.innerHTML = '<div class="empty-state"><p>Sign in as an organizer to access this page.</p></div>';
      return;
    }

    if (state.user.role !== "admin") {
      list.innerHTML = '<div class="empty-state"><p>This area is reserved for organizers.</p></div>';
      return;
    }

    if (!state.organizerProposals.length) {
      list.innerHTML = '<div class="empty-state"><p>No proposals matched the current filter.</p></div>';
      return;
    }

    list.innerHTML = state.organizerProposals.map(function (proposal) {
      return (
        '<article class="proposal-card">' +
          "<h4>" + escapeHTML(proposal.title) + "</h4>" +
          '<div class="proposal-meta">' +
            '<span class="pill">' + escapeHTML(proposal.conferenceDisplayName) + "</span>" +
            '<span class="pill">' + escapeHTML(proposal.speakerName) + "</span>" +
            '<span class="pill">' + escapeHTML(proposal.talkDuration) + "</span>" +
          "</div>" +
          '<p class="proposal-summary">' + escapeHTML(truncate(proposal.abstract, 220)) + "</p>" +
          '<div class="proposal-actions compact">' +
            '<button type="button" class="button neutral" data-edit-admin-proposal="' + escapeHTML(proposal.id) + '">Edit</button>' +
            '<select data-status-select="' + escapeHTML(proposal.id) + '">' +
              renderStatusOptions(proposal.status) +
            "</select>" +
            '<button type="button" class="button neutral" data-save-status="' + escapeHTML(proposal.id) + '">Save Status</button>' +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  function renderStatusOptions(selectedStatus) {
    var statuses = ["submitted", "accepted", "rejected", "withdrawn"];
    return statuses.map(function (status) {
      var selected = status === selectedStatus ? ' selected="selected"' : "";
      return '<option value="' + escapeHTML(status) + '"' + selected + ">" + escapeHTML(status) + "</option>";
    }).join("");
  }

  function resetOrganizerEditor() {
    var form = document.getElementById("organizer-editor-form");
    var placeholder = document.getElementById("organizer-editor-placeholder");
    if (!form || !placeholder) return;

    form.reset();
    form.hidden = true;
    placeholder.hidden = false;
    if (state.conferences.length) {
      populateSelect("organizer-editor-conference-id", state.conferences, null, "id", "displayName");
    }
    toggleWorkshopSection(form, "organizer-edit-workshop-section", form.elements.talkDuration.value);
    showStatus("organizer-editor-status", null);
  }

  function loadOrganizerProposalIntoEditor(proposalID) {
    var proposal = state.organizerProposals.find(function (item) { return item.id === proposalID; });
    var form = document.getElementById("organizer-editor-form");
    var placeholder = document.getElementById("organizer-editor-placeholder");
    if (!proposal || !form || !placeholder) return;

    form.hidden = false;
    placeholder.hidden = true;

    form.elements.proposalID.value = proposal.id || "";
    form.elements.conferenceId.value = proposal.conferenceId || "";
    form.elements.talkDuration.value = proposal.talkDuration || "20min";
    form.elements.githubUsername.value = proposal.githubUsername || proposal.speakerUsername || "";
    form.elements.iconURL.value = proposal.iconURL || "";
    form.elements.title.value = proposal.title || "";
    form.elements.titleJA.value = proposal.titleJA || "";
    form.elements.abstract.value = proposal.abstract || "";
    form.elements.abstractJA.value = proposal.abstractJA || "";
    form.elements.talkDetail.value = proposal.talkDetail || "";
    form.elements.speakerName.value = proposal.speakerName || "";
    form.elements.speakerEmail.value = proposal.speakerEmail || "";
    form.elements.jobTitle.value = proposal.jobTitle || "";
    form.elements.jobTitleJa.value = proposal.jobTitleJa || "";
    form.elements.bio.value = proposal.bio || "";
    form.elements.bioJa.value = proposal.bioJa || "";
    form.elements.notes.value = proposal.notes || "";
    populateWorkshopFields(form, proposal.workshopDetails, proposal.workshopDetailsJA, proposal.coInstructors, {
      coInstructorPrefixes: ["organizer-edit-co1", "organizer-edit-co2"],
      includeJapaneseFields: true
    });
    toggleWorkshopSection(form, "organizer-edit-workshop-section", form.elements.talkDuration.value);
  }

  function formatDateTime(value) {
    if (!value) return "";
    var date = new Date(value);
    if (Number.isNaN(date.getTime())) return value;
    return date.toLocaleString("ja-JP", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit"
    });
  }

  function toISODateTime(localValue) {
    if (!localValue) return null;
    var date = new Date(localValue);
    if (Number.isNaN(date.getTime())) return null;
    return date.toISOString();
  }

  function renderOrganizerSlots() {
    var list = document.getElementById("organizer-slot-list");
    if (!list) return;

    if (!state.user || state.user.role !== "admin") {
      list.innerHTML = '<div class="empty-state"><p>Organizer access is required to manage timetable slots.</p></div>';
      return;
    }

    if (!state.organizerSlots.length) {
      list.innerHTML = '<div class="empty-state"><p>No timetable slots found for the selected conference.</p></div>';
      return;
    }

    list.innerHTML = state.organizerSlots.map(function (slot) {
      var title = slot.proposalTitle || slot.customTitle || slot.slotType;
      var meta = [
        "Day " + slot.day,
        formatDateTime(slot.startTime),
        slot.place || "No place"
      ];
      if (slot.speakerName) {
        meta.push(slot.speakerName);
      }

      return (
        '<article class="proposal-card">' +
          "<h4>" + escapeHTML(title) + "</h4>" +
          '<div class="proposal-meta">' +
            meta.map(function (item) { return '<span class="pill">' + escapeHTML(item) + "</span>"; }).join("") +
          "</div>" +
          '<div class="proposal-actions compact">' +
            '<button type="button" class="button neutral" data-edit-slot="' + escapeHTML(slot.id) + '">Edit</button>' +
            '<button type="button" class="button neutral" data-move-slot-up="' + escapeHTML(slot.id) + '">Move Up</button>' +
            '<button type="button" class="button neutral" data-move-slot-down="' + escapeHTML(slot.id) + '">Move Down</button>' +
            '<button type="button" class="button danger" data-delete-slot="' + escapeHTML(slot.id) + '">Delete Slot</button>' +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  function populateProposalSelectForSlots() {
    var select = document.getElementById("organizer-slot-proposal-id");
    if (!select) return;

    var html = '<option value="">No linked proposal</option>';
    state.organizerProposals.forEach(function (proposal) {
      html += '<option value="' + escapeHTML(proposal.id) + '">';
      html += escapeHTML(proposal.title + " - " + proposal.speakerName);
      html += "</option>";
    });
    select.innerHTML = html;
  }

  function populateSlotEditorProposalSelect() {
    var select = document.getElementById("organizer-slot-editor-proposal-id");
    if (!select) return;

    var html = '<option value="">No linked proposal</option>';
    state.organizerProposals.forEach(function (proposal) {
      html += '<option value="' + escapeHTML(proposal.id) + '">';
      html += escapeHTML(proposal.title + " - " + proposal.speakerName);
      html += "</option>";
    });
    select.innerHTML = html;
  }

  function toDateTimeLocalValue(value) {
    if (!value) return "";
    var date = new Date(value);
    if (Number.isNaN(date.getTime())) return "";
    var offset = date.getTimezoneOffset();
    var local = new Date(date.getTime() - offset * 60000);
    return local.toISOString().slice(0, 16);
  }

  function resetSlotEditor() {
    var form = document.getElementById("organizer-slot-editor-form");
    var placeholder = document.getElementById("organizer-slot-editor-placeholder");
    if (!form || !placeholder) return;

    form.reset();
    form.hidden = true;
    placeholder.hidden = false;
    populateSlotEditorProposalSelect();
    showStatus("organizer-slot-editor-status", null);
  }

  function loadSlotIntoEditor(slotID) {
    var slot = state.organizerSlots.find(function (item) { return item.id === slotID; });
    var form = document.getElementById("organizer-slot-editor-form");
    var placeholder = document.getElementById("organizer-slot-editor-placeholder");
    if (!slot || !form || !placeholder) return;

    form.hidden = false;
    placeholder.hidden = true;
    form.elements.slotID.value = slot.id || "";
    form.elements.day.value = String(slot.day || 1);
    form.elements.slotType.value = slot.slotType || "talk";
    form.elements.proposalId.value = slot.proposalId || "";
    form.elements.place.value = slot.place || "";
    form.elements.startTime.value = toDateTimeLocalValue(slot.startTime);
    form.elements.endTime.value = toDateTimeLocalValue(slot.endTime);
    form.elements.customTitle.value = slot.customTitle || "";
  }

  function moveSlot(slotID, direction) {
    var slot = state.organizerSlots.find(function (item) { return item.id === slotID; });
    if (!slot) return;

    var sameDay = state.organizerSlots
      .filter(function (item) { return item.day === slot.day; })
      .sort(function (lhs, rhs) { return lhs.sortOrder - rhs.sortOrder; });
    var index = sameDay.findIndex(function (item) { return item.id === slotID; });
    if (index < 0) return;

    var targetIndex = direction === "up" ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= sameDay.length) return;

    var current = sameDay[index];
    var target = sameDay[targetIndex];
    var oldOrder = current.sortOrder;
    current.sortOrder = target.sortOrder;
    target.sortOrder = oldOrder;

    state.organizerSlots = state.organizerSlots.slice().sort(function (lhs, rhs) {
      if (lhs.day !== rhs.day) return lhs.day - rhs.day;
      return lhs.sortOrder - rhs.sortOrder;
    });
    renderOrganizerSlots();
    showStatus("organizer-slot-editor-status", "Reorder staged locally. Use Apply Day Order to save it.", "success");
  }

  function renderFeedback() {
    var list = document.getElementById("feedback-list");
    var empty = document.getElementById("feedback-empty");
    if (!list || !empty) return;

    if (!state.user) {
      list.innerHTML = "";
      empty.hidden = false;
      empty.innerHTML = "<p>Sign in to review feedback for your talks.</p>";
      return;
    }

    if (!state.feedbackGroups.length) {
      list.innerHTML = "";
      empty.hidden = false;
      empty.innerHTML = "<p>No feedback has been submitted for your talks yet.</p>";
      return;
    }

    empty.hidden = true;
    list.innerHTML = state.feedbackGroups.map(function (group) {
      return (
        '<article class="proposal-card">' +
          "<h4>" + escapeHTML(group.proposalTitle) + "</h4>" +
          '<div class="proposal-meta"><span class="pill">' + escapeHTML(String(group.feedbacks.length)) + ' comment(s)</span></div>' +
          '<div class="feedback-thread">' +
            group.feedbacks.map(function (item) {
              return (
                '<div class="feedback-item">' +
                  '<time>' + escapeHTML(formatDateTime(item.createdAt)) + "</time>" +
                  "<p>" + escapeHTML(item.comment) + "</p>" +
                "</div>"
              );
            }).join("") +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  function selectedConferencePathFromID(conferenceID) {
    var conference = state.conferences.find(function (item) { return item.id === conferenceID; });
    return conference ? conference.path : "";
  }

  function updateExportLinks() {
    var filter = document.getElementById("organizer-conference-filter");
    var conferencePath = filter ? filter.value : "";
    var query = conferencePath ? "?conference=" + encodeURIComponent(conferencePath) : "";

    var proposalsLink = document.getElementById("export-proposals-link");
    var speakersLink = document.getElementById("export-speakers-link");
    var timetableLink = document.getElementById("export-timetable-link");

    if (proposalsLink) proposalsLink.href = apiBaseURL() + "/api/v1/admin/proposals/export" + query;
    if (speakersLink) speakersLink.href = apiBaseURL() + "/api/v1/admin/proposals/speakers-export" + query;
    if (timetableLink) timetableLink.href = apiBaseURL() + "/api/v1/admin/timetable/export";
  }

  async function bootstrapSubmitPage() {
    var form = document.getElementById("submit-form");
    if (!form) return;
    wireWorkshopToggle(form, "talkDuration", "submit-workshop-section");
    updateAvatarPreview(form);
    if (form.elements.iconURL) {
      form.elements.iconURL.addEventListener("input", function () {
        updateAvatarPreview(form);
      });
      form.elements.iconURL.addEventListener("change", function () {
        updateAvatarPreview(form);
      });
    }

    try {
      var openConferences = await loadOpenConferences();
      populateSelect("submit-conference-path", openConferences, null, "path", "displayName");
      prefillSpeakerFields(form, state.user);
      if (!openConferences.length) {
        showStatus("submit-status", "There is no open conference right now.", "error");
      }
    } catch (error) {
      showStatus("submit-status", error.message, "error");
    }

    form.addEventListener("submit", async function (event) {
      event.preventDefault();
      if (!state.user) {
        showStatus("submit-status", "Sign in before submitting a proposal.", "error");
        return;
      }

      var payload = readFormJSON(form, [
        "conferencePath",
        "title",
        "abstract",
        "talkDetail",
        "talkDuration",
        "speakerName",
        "speakerEmail",
        "bio",
        "iconURL",
        "notes"
      ]);
      if (payload.talkDuration === "workshop") {
        Object.assign(payload, readWorkshopPayload(form, {
          coInstructorPrefixes: ["submit-co1", "submit-co2"],
          includeJapaneseFields: false
        }));
      }

      try {
        await apiRequest("/api/v1/proposals", {
          method: "POST",
          body: JSON.stringify(payload)
        });
        showStatus("submit-status", "Proposal submitted successfully.", "success");
        form.reset();
        populateSelect("submit-conference-path", state.openConferences, null, "path", "displayName");
        prefillSpeakerFields(form, state.user);
        updateAvatarPreview(form);
        toggleWorkshopSection(form, "submit-workshop-section", form.elements.talkDuration.value);
      } catch (error) {
        showStatus("submit-status", error.message, "error");
      }
    });
  }

  async function bootstrapProfilePage() {
    var form = document.getElementById("profile-form");
    if (!form) return;

    if (!state.user) {
      showStatus("profile-status", "Sign in to edit your profile.", "error");
      return;
    }

    form.elements.displayName.value = state.user.displayName || "";
    form.elements.email.value = state.user.email || "";
    form.elements.bio.value = state.user.bio || "";
    form.elements.url.value = state.user.url || "";
    form.elements.organization.value = state.user.organization || "";
    form.elements.avatarURL.value = state.user.avatarURL || "";

    form.addEventListener("submit", async function (event) {
      event.preventDefault();

      var payload = {
        displayName: form.elements.displayName.value.trim(),
        email: form.elements.email.value.trim(),
        bio: form.elements.bio.value.trim(),
        url: form.elements.url.value.trim(),
        organization: form.elements.organization.value.trim(),
        avatarURL: form.elements.avatarURL.value.trim()
      };

      try {
        state.user = await apiRequest("/api/v1/auth/me", {
          method: "PUT",
          body: JSON.stringify(payload)
        });
        updateAuthState(state.user);
        showStatus("profile-status", "Profile updated.", "success");
      } catch (error) {
        showStatus("profile-status", error.message, "error");
      }
    });
  }

  async function refreshFeedback() {
    try {
      state.feedbackGroups = await apiRequest("/api/v1/feedback/my-talks");
      renderFeedback();
      showStatus("feedback-status", "Loaded feedback for " + state.feedbackGroups.length + " talk(s).", "success");
    } catch (error) {
      state.feedbackGroups = [];
      renderFeedback();
      showStatus("feedback-status", error.message, "error");
    }
  }

  async function bootstrapFeedbackPage() {
    var refreshButton = document.getElementById("feedback-refresh");
    if (!refreshButton) return;
    refreshButton.addEventListener("click", refreshFeedback);
    await refreshFeedback();
  }

  async function refreshMyProposals() {
    try {
      state.myProposals = await apiRequest("/api/v1/proposals/mine");
      renderMyProposals();
      showStatus("my-proposals-status", "Loaded " + state.myProposals.length + " proposal(s).", "success");
    } catch (error) {
      state.myProposals = [];
      renderMyProposals();
      showStatus("my-proposals-status", error.message, "error");
    }
  }

  async function bootstrapMyProposalsPage() {
    var refreshButton = document.getElementById("my-proposals-refresh");
    var list = document.getElementById("my-proposals-list");
    var editorForm = document.getElementById("proposal-editor-form");
    var withdrawButton = document.getElementById("proposal-withdraw-button");
    if (!refreshButton || !list || !editorForm || !withdrawButton) return;
    wireWorkshopToggle(editorForm, "talkDuration", "speaker-edit-workshop-section");

    refreshButton.addEventListener("click", refreshMyProposals);

    list.addEventListener("click", function (event) {
      var button = event.target.closest("[data-edit-proposal]");
      if (!button) return;
      loadProposalIntoEditor(button.getAttribute("data-edit-proposal"));
      showStatus("proposal-editor-status", null);
    });

    editorForm.addEventListener("submit", async function (event) {
      event.preventDefault();
      var proposalID = editorForm.elements.proposalID.value;
      if (!proposalID) return;

      var payload = readFormJSON(editorForm, [
        "title",
        "abstract",
        "talkDetail",
        "talkDuration",
        "speakerName",
        "speakerEmail",
        "bio",
        "iconURL",
        "notes"
      ]);
      if (payload.talkDuration === "workshop") {
        Object.assign(payload, readWorkshopPayload(editorForm, {
          coInstructorPrefixes: ["speaker-edit-co1", "speaker-edit-co2"],
          includeJapaneseFields: false
        }));
      }

      try {
        await apiRequest("/api/v1/proposals/" + encodeURIComponent(proposalID), {
          method: "PUT",
          body: JSON.stringify(payload)
        });
        showStatus("proposal-editor-status", "Proposal updated.", "success");
        await refreshMyProposals();
        loadProposalIntoEditor(proposalID);
      } catch (error) {
        showStatus("proposal-editor-status", error.message, "error");
      }
    });

    withdrawButton.addEventListener("click", async function () {
      var proposalID = editorForm.elements.proposalID.value;
      if (!proposalID) return;

      try {
        await apiRequest("/api/v1/proposals/" + encodeURIComponent(proposalID) + "/withdraw", {
          method: "POST"
        });
        showStatus("proposal-editor-status", "Proposal withdrawn.", "success");
        await refreshMyProposals();
      } catch (error) {
        showStatus("proposal-editor-status", error.message, "error");
      }
    });

    await refreshMyProposals();
    var initialProposalID = extractMyProposalRouteID();
    if (initialProposalID) {
      loadProposalIntoEditor(initialProposalID);
    }
  }

  async function refreshOrganizerProposals() {
    var filter = document.getElementById("organizer-conference-filter");
    var query = "";
    if (filter && filter.value) {
      query = "?conference=" + encodeURIComponent(filter.value);
    }

    try {
      state.organizerProposals = await apiRequest("/api/v1/admin/proposals" + query);
      renderOrganizerProposals();
      populateProposalSelectForSlots();
      populateSlotEditorProposalSelect();
      updateExportLinks();
      showStatus("organizer-status", "Loaded " + state.organizerProposals.length + " proposal(s).", "success");
    } catch (error) {
      state.organizerProposals = [];
      renderOrganizerProposals();
      showStatus("organizer-status", error.message, "error");
    }
  }

  async function refreshOrganizerSlots() {
    var filter = document.getElementById("organizer-slot-conference-filter");
    var query = "";
    if (filter && filter.value) {
      query = "?conference=" + encodeURIComponent(filter.value);
    }

    try {
      state.organizerSlots = await apiRequest("/api/v1/admin/timetable/slots" + query);
      renderOrganizerSlots();
      showStatus("organizer-timetable-status", "Loaded " + state.organizerSlots.length + " slot(s).", "success");
    } catch (error) {
      state.organizerSlots = [];
      renderOrganizerSlots();
      showStatus("organizer-timetable-status", error.message, "error");
    }
  }

  async function refreshWorkshops() {
    try {
      var payload = await apiRequest("/api/v1/workshops");
      state.workshops = payload.workshops || [];
      renderWorkshops();
      showStatus("workshops-status", null);
    } catch (error) {
      state.workshops = [];
      renderWorkshops();
      showStatus("workshops-status", null);
    }
  }

  function populateWorkshopApplicationChoices(session) {
    var first = document.getElementById("workshop-first-choice");
    var second = document.getElementById("workshop-second-choice");
    var third = document.getElementById("workshop-third-choice");
    if (!first || !second || !third) return;

    var existing = session.existingSelections || {};
    first.innerHTML = renderWorkshopChoiceOptions(session.workshops || [], existing.firstChoiceID);
    second.innerHTML = renderWorkshopChoiceOptions(session.workshops || [], existing.secondChoiceID);
    third.innerHTML = renderWorkshopChoiceOptions(session.workshops || [], existing.thirdChoiceID);
    if (!first.value && session.workshops && session.workshops[0]) {
      first.value = session.workshops[0].id;
    }
  }

  async function bootstrapWorkshopsPage() {
    var refreshButton = document.getElementById("workshops-refresh");
    var verifyForm = document.getElementById("workshop-verify-form");
    var applyForm = document.getElementById("workshop-apply-form");
    var statusForm = document.getElementById("workshop-status-form");
    var statusResult = document.getElementById("workshop-status-result");
    if (!verifyForm || !applyForm || !statusForm || !statusResult) return;

    wireWorkshopModal();

    if (refreshButton) {
      refreshButton.addEventListener("click", refreshWorkshops);
    }

    verifyForm.addEventListener("submit", async function (event) {
      event.preventDefault();

      try {
        state.workshopVerifySession = await apiRequest("/api/v1/workshops/verify", {
          method: "POST",
          body: JSON.stringify({ email: verifyForm.elements.email.value.trim() })
        });
        applyForm.hidden = false;
        applyForm.elements.verifyToken.value = state.workshopVerifySession.verifyToken || "";
        applyForm.elements.applicantName.value = state.workshopVerifySession.applicantName || "";
        populateWorkshopApplicationChoices(state.workshopVerifySession);
        showStatus("workshop-verify-status", state.workshopVerifySession.isPostLottery ? "Ticket verified. Choose one workshop with remaining capacity." : "Ticket verified. Select your workshop choices.", "success");
      } catch (error) {
        applyForm.hidden = true;
        showStatus("workshop-verify-status", error.message, "error");
      }
    });

    applyForm.addEventListener("submit", async function (event) {
      event.preventDefault();

      var payload = {
        applicantName: applyForm.elements.applicantName.value.trim(),
        verifyToken: applyForm.elements.verifyToken.value,
        firstChoiceID: applyForm.elements.firstChoiceID.value
      };
      if (applyForm.elements.secondChoiceID.value) payload.secondChoiceID = applyForm.elements.secondChoiceID.value;
      if (applyForm.elements.thirdChoiceID.value) payload.thirdChoiceID = applyForm.elements.thirdChoiceID.value;

      try {
        var response = await apiRequest("/api/v1/workshops/apply", {
          method: "POST",
          body: JSON.stringify(payload)
        });
        renderWorkshopStatusResult(response.application);
        showStatus("workshop-verify-status", response.isPostLottery ? "Workshop assigned." : "Workshop application saved.", "success");
        statusForm.elements.email.value = response.application.email || "";
      } catch (error) {
        showStatus("workshop-verify-status", error.message, "error");
      }
    });

    statusForm.addEventListener("submit", async function (event) {
      event.preventDefault();

      try {
        var response = await apiRequest("/api/v1/workshops/status", {
          method: "POST",
          body: JSON.stringify({ email: statusForm.elements.email.value.trim() })
        });
        renderWorkshopStatusResult(response.application);
        showStatus("workshop-status-check-status", response.found ? "Application loaded." : "No application found for that email.", response.found ? "success" : "error");
      } catch (error) {
        renderWorkshopStatusResult(null);
        showStatus("workshop-status-check-status", error.message, "error");
      }
    });

    statusResult.addEventListener("click", async function (event) {
      var deleteButton = event.target.closest("[data-workshop-delete-token]");
      var cancelButton = event.target.closest("[data-workshop-cancel-token]");
      var path = null;
      var token = null;
      var successMessage = "";

      if (deleteButton) {
        path = "/api/v1/workshops/delete";
        token = deleteButton.getAttribute("data-workshop-delete-token");
        successMessage = "Pending application deleted.";
      } else if (cancelButton) {
        path = "/api/v1/workshops/cancel";
        token = cancelButton.getAttribute("data-workshop-cancel-token");
        successMessage = "Workshop participation cancelled.";
      }

      if (!path || !token) return;

      try {
        await apiRequest(path, {
          method: "POST",
          body: JSON.stringify({ token: token })
        });
        renderWorkshopStatusResult(null);
        showStatus("workshop-status-check-status", successMessage, "success");
      } catch (error) {
        showStatus("workshop-status-check-status", error.message, "error");
      }
    });

    await refreshWorkshops();
  }

  function renderOrganizerWorkshops() {
    var list = document.getElementById("organizer-workshops-list");
    if (!list) return;

    if (!state.user || state.user.role !== "admin") {
      list.innerHTML = '<div class="empty-state"><p>Organizer access is required to manage workshops.</p></div>';
      return;
    }

    if (!state.organizerWorkshops.length) {
      list.innerHTML = '<div class="empty-state"><p>No workshop registrations have been prepared yet.</p></div>';
      return;
    }

    list.innerHTML = state.organizerWorkshops.map(function (workshop) {
      return (
        '<article class="proposal-card">' +
          "<h4>" + escapeHTML(workshop.proposalTitle) + "</h4>" +
          '<div class="proposal-meta">' +
            '<span class="pill">' + escapeHTML(workshop.speakerName) + "</span>" +
            '<span class="pill">' + escapeHTML(String(workshop.applicationCount)) + " applications</span>" +
            '<span class="pill">' + escapeHTML(String(workshop.remainingCapacity)) + " seats left</span>" +
          "</div>" +
          '<div class="form-grid compact-grid">' +
            '<label class="form-field"><span class="field-label">Capacity</span><input type="number" min="1" data-workshop-capacity="' + escapeHTML(workshop.registrationID) + '" value="' + escapeHTML(String(workshop.capacity)) + '"></label>' +
            '<label class="form-field"><span class="field-label">Luma Event ID</span><input type="text" data-workshop-luma-event="' + escapeHTML(workshop.registrationID) + '" value="' + escapeHTML(workshop.lumaEventID || "") + '"></label>' +
          "</div>" +
          '<div class="form-actions split">' +
            '<button type="button" class="button neutral" data-save-workshop-capacity="' + escapeHTML(workshop.registrationID) + '">Save Capacity</button>' +
            '<button type="button" class="button neutral" data-save-workshop-luma="' + escapeHTML(workshop.registrationID) + '">Save Luma ID</button>' +
            '<button type="button" class="button primary" data-create-workshop-luma="' + escapeHTML(workshop.registrationID) + '">Create Luma Event</button>' +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  function populateWorkshopFilter() {
    var select = document.getElementById("organizer-workshop-filter");
    if (!select) return;
    var html = '<option value="">All workshops</option>';
    state.organizerWorkshops.forEach(function (workshop) {
      html += '<option value="' + escapeHTML(workshop.registrationID) + '">' + escapeHTML(workshop.proposalTitle) + "</option>";
    });
    select.innerHTML = html;
  }

  async function refreshOrganizerWorkshops() {
    try {
      state.organizerWorkshops = await apiRequest("/api/v1/admin/workshops");
      renderOrganizerWorkshops();
      populateWorkshopFilter();
      showStatus("organizer-workshops-status", "Loaded " + state.organizerWorkshops.length + " workshop registration(s).", "success");
    } catch (error) {
      state.organizerWorkshops = [];
      renderOrganizerWorkshops();
      showStatus("organizer-workshops-status", error.message, "error");
    }
  }

  function renderOrganizerWorkshopApplications() {
    var list = document.getElementById("organizer-workshop-applications-list");
    if (!list) return;

    if (!state.organizerWorkshopApplications.length) {
      list.innerHTML = '<div class="empty-state"><p>No workshop applications matched the current filter.</p></div>';
      return;
    }

    list.innerHTML = state.organizerWorkshopApplications.map(function (application) {
      return (
        '<article class="proposal-card">' +
          "<h4>" + escapeHTML(application.applicantName) + "</h4>" +
          '<div class="proposal-meta">' +
            '<span class="pill">' + escapeHTML(application.status) + "</span>" +
            '<span class="pill">' + escapeHTML(application.email) + "</span>" +
          "</div>" +
          '<p class="proposal-summary">1st: ' + escapeHTML(application.firstChoice) + (application.assignedWorkshop ? " / assigned: " + escapeHTML(application.assignedWorkshop) : "") + "</p>" +
          '<div class="proposal-actions compact">' +
            '<button type="button" class="button danger" data-delete-workshop-application="' + escapeHTML(application.id) + '">Delete</button>' +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  async function refreshOrganizerWorkshopApplications() {
    var filter = document.getElementById("organizer-workshop-filter");
    var query = filter && filter.value ? "?workshop=" + encodeURIComponent(filter.value) : "";
    try {
      state.organizerWorkshopApplications = await apiRequest("/api/v1/admin/workshop-applications" + query);
      renderOrganizerWorkshopApplications();
      showStatus("organizer-workshop-applications-status", "Loaded " + state.organizerWorkshopApplications.length + " application(s).", "success");
    } catch (error) {
      state.organizerWorkshopApplications = [];
      renderOrganizerWorkshopApplications();
      showStatus("organizer-workshop-applications-status", error.message, "error");
    }
  }

  function renderOrganizerWorkshopResults() {
    var list = document.getElementById("organizer-workshop-results-list");
    if (!list) return;

    if (!state.organizerWorkshopResults.length) {
      list.innerHTML = '<div class="empty-state"><p>No lottery results available yet.</p></div>';
      return;
    }

    list.innerHTML = state.organizerWorkshopResults.map(function (result) {
      return (
        '<article class="proposal-card">' +
          "<h4>" + escapeHTML(result.workshopTitle) + "</h4>" +
          '<div class="proposal-meta">' +
            '<span class="pill">Capacity ' + escapeHTML(String(result.capacity)) + "</span>" +
            '<span class="pill">' + escapeHTML(result.ticketsSent ? "Tickets sent" : "Tickets pending") + "</span>" +
          "</div>" +
          '<div class="feedback-thread">' +
            (result.winners || []).map(function (winner) {
              return '<div class="feedback-item"><p>' + escapeHTML(winner.name + " <" + winner.email + ">") + "</p></div>";
            }).join("") +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  async function refreshOrganizerWorkshopResults() {
    try {
      state.organizerWorkshopResults = await apiRequest("/api/v1/admin/workshops/results");
      renderOrganizerWorkshopResults();
      showStatus("organizer-workshop-results-status", "Loaded " + state.organizerWorkshopResults.length + " result set(s).", "success");
    } catch (error) {
      state.organizerWorkshopResults = [];
      renderOrganizerWorkshopResults();
      showStatus("organizer-workshop-results-status", error.message, "error");
    }
  }

  async function bootstrapOrganizerPage() {
    var createForm = document.getElementById("organizer-create-form");
    var refreshButton = document.getElementById("organizer-refresh");
    var filter = document.getElementById("organizer-conference-filter");
    var list = document.getElementById("organizer-proposals");
    var lookupButton = document.getElementById("organizer-lookup-button");
    var importForm = document.getElementById("organizer-import-form");
    var slotForm = document.getElementById("organizer-slot-form");
    var slotList = document.getElementById("organizer-slot-list");
    var slotFilter = document.getElementById("organizer-slot-conference-filter");
    var slotEditorForm = document.getElementById("organizer-slot-editor-form");
    var slotEditorResetButton = document.getElementById("organizer-slot-editor-reset");
    var slotReorderButton = document.getElementById("organizer-slot-reorder-button");
    var editorForm = document.getElementById("organizer-editor-form");
    var editorResetButton = document.getElementById("organizer-editor-reset");
    var deleteProposalButton = document.getElementById("organizer-delete-proposal-button");
    var workshopRefreshButton = document.getElementById("organizer-workshops-refresh");
    var workshopList = document.getElementById("organizer-workshops-list");
    var workshopFilter = document.getElementById("organizer-workshop-filter");
    var workshopApplicationsRefreshButton = document.getElementById("organizer-workshop-applications-refresh");
    var workshopApplicationsList = document.getElementById("organizer-workshop-applications-list");
    var workshopLotteryButton = document.getElementById("organizer-workshop-lottery-button");
    var workshopSendTicketsButton = document.getElementById("organizer-workshop-send-tickets-button");
    var workshopResultsRefreshButton = document.getElementById("organizer-workshop-results-refresh");
    if (!createForm || !refreshButton || !filter || !list || !lookupButton || !importForm || !slotForm || !slotList || !slotFilter || !slotEditorForm || !slotEditorResetButton || !slotReorderButton || !editorForm || !editorResetButton || !deleteProposalButton || !workshopRefreshButton || !workshopList || !workshopFilter || !workshopApplicationsRefreshButton || !workshopApplicationsList || !workshopLotteryButton || !workshopSendTicketsButton || !workshopResultsRefreshButton) return;
    wireWorkshopToggle(createForm, "talkDuration", "organizer-create-workshop-section");
    wireWorkshopToggle(editorForm, "talkDuration", "organizer-edit-workshop-section");

    try {
      await loadAllConferences();
      populateSelect("organizer-conference-id", state.conferences, null, "id", "displayName");
      populateSelect("organizer-conference-filter", state.conferences, "All conferences", "path", "displayName");
      populateSelect("organizer-import-conference-id", state.conferences, null, "id", "displayName");
      populateSelect("organizer-slot-conference-id", state.conferences, null, "id", "displayName");
      populateSelect("organizer-slot-conference-filter", state.conferences, null, "path", "displayName");
      populateSelect("organizer-editor-conference-id", state.conferences, null, "id", "displayName");
      updateExportLinks();
    } catch (error) {
      showStatus("organizer-status", error.message, "error");
    }

    refreshButton.addEventListener("click", refreshOrganizerProposals);
    filter.addEventListener("change", function () {
      refreshOrganizerProposals();
      updateExportLinks();
    });
    slotFilter.addEventListener("change", refreshOrganizerSlots);
    workshopRefreshButton.addEventListener("click", refreshOrganizerWorkshops);
    workshopApplicationsRefreshButton.addEventListener("click", refreshOrganizerWorkshopApplications);
    workshopResultsRefreshButton.addEventListener("click", refreshOrganizerWorkshopResults);
    workshopFilter.addEventListener("change", refreshOrganizerWorkshopApplications);
    editorResetButton.addEventListener("click", resetOrganizerEditor);
    slotEditorResetButton.addEventListener("click", resetSlotEditor);

    lookupButton.addEventListener("click", async function () {
      var username = (createForm.elements.githubUsername.value || "").trim();
      if (!username) {
        showStatus("organizer-create-status", "Enter a GitHub username first.", "error");
        return;
      }

      try {
        var lookup = await apiRequest("/api/v1/admin/users/lookup/" + encodeURIComponent(username));
        if (lookup.name) createForm.elements.speakerName.value = lookup.name;
        if (lookup.email) createForm.elements.speakerEmail.value = lookup.email;
        if (lookup.bio) createForm.elements.bio.value = lookup.bio;
        if (lookup.avatarURL) createForm.elements.iconURL.value = lookup.avatarURL;
        showStatus("organizer-create-status", "Loaded speaker data for @" + username + ".", "success");
      } catch (error) {
        showStatus("organizer-create-status", error.message, "error");
      }
    });

    createForm.addEventListener("submit", async function (event) {
      event.preventDefault();
      var payload = readFormJSON(createForm, [
        "conferenceId",
        "title",
        "abstract",
        "talkDetail",
        "talkDuration",
        "speakerName",
        "speakerEmail",
        "bio",
        "githubUsername",
        "iconURL",
        "notes"
      ]);
      if (payload.talkDuration === "workshop") {
        Object.assign(payload, readWorkshopPayload(createForm, {
          coInstructorPrefixes: ["organizer-create-co1", "organizer-create-co2"],
          includeJapaneseFields: false
        }));
      }

      try {
        await apiRequest("/api/v1/admin/proposals", {
          method: "POST",
          body: JSON.stringify(payload)
        });
        showStatus("organizer-create-status", "Proposal created.", "success");
        createForm.reset();
        populateSelect("organizer-conference-id", state.conferences, null, "id", "displayName");
        populateSelect("organizer-import-conference-id", state.conferences, null, "id", "displayName");
        toggleWorkshopSection(createForm, "organizer-create-workshop-section", createForm.elements.talkDuration.value);
        await refreshOrganizerProposals();
      } catch (error) {
        showStatus("organizer-create-status", error.message, "error");
      }
    });

    importForm.addEventListener("submit", async function (event) {
      event.preventDefault();

      var fileInput = importForm.elements.csvFile;
      if (!fileInput || !fileInput.files || !fileInput.files[0]) {
        showStatus("organizer-import-status", "Choose a CSV or JSON file to import.", "error");
        return;
      }

      var formData = new FormData();
      formData.append("csvFile", fileInput.files[0]);
      formData.append("conferenceId", importForm.elements.conferenceId.value);
      if (importForm.elements.githubUsername.value.trim()) {
        formData.append("githubUsername", importForm.elements.githubUsername.value.trim());
      }
      formData.append("skipDuplicates", importForm.elements.skipDuplicates.checked ? "true" : "false");

      try {
        await apiRequest("/api/v1/admin/proposals/import", {
          method: "POST",
          body: formData
        });
        showStatus("organizer-import-status", "Import completed.", "success");
        importForm.reset();
        populateSelect("organizer-import-conference-id", state.conferences, null, "id", "displayName");
        await refreshOrganizerProposals();
      } catch (error) {
        showStatus("organizer-import-status", error.message, "error");
      }
    });

    slotForm.addEventListener("submit", async function (event) {
      event.preventDefault();

      var payload = {
        conferenceId: slotForm.elements.conferenceId.value,
        day: Number(slotForm.elements.day.value),
        startTime: toISODateTime(slotForm.elements.startTime.value),
        slotType: slotForm.elements.slotType.value
      };

      var proposalId = slotForm.elements.proposalId.value.trim();
      var endTime = toISODateTime(slotForm.elements.endTime.value);
      var customTitle = slotForm.elements.customTitle.value.trim();
      var place = slotForm.elements.place.value.trim();
      if (proposalId) payload.proposalId = proposalId;
      if (endTime) payload.endTime = endTime;
      if (customTitle) payload.customTitle = customTitle;
      if (place) payload.place = place;

      if (!payload.startTime) {
        showStatus("organizer-timetable-status", "Start time is required.", "error");
        return;
      }

      try {
        await apiRequest("/api/v1/admin/timetable/slots", {
          method: "POST",
          body: JSON.stringify(payload)
        });
        showStatus("organizer-timetable-status", "Timetable slot created.", "success");
        slotForm.reset();
        slotForm.elements.day.value = "1";
        populateSelect("organizer-slot-conference-id", state.conferences, null, "id", "displayName");
        populateProposalSelectForSlots();
        populateSlotEditorProposalSelect();
        await refreshOrganizerSlots();
      } catch (error) {
        showStatus("organizer-timetable-status", error.message, "error");
      }
    });

    list.addEventListener("click", async function (event) {
      var editButton = event.target.closest("[data-edit-admin-proposal]");
      if (editButton) {
        loadOrganizerProposalIntoEditor(editButton.getAttribute("data-edit-admin-proposal"));
        return;
      }

      var saveButton = event.target.closest("[data-save-status]");
      if (!saveButton) return;

      var proposalID = saveButton.getAttribute("data-save-status");
      var select = list.querySelector('[data-status-select="' + proposalID + '"]');
      if (!proposalID || !select) return;

      try {
        await apiRequest("/api/v1/admin/proposals/" + encodeURIComponent(proposalID) + "/status", {
          method: "POST",
          body: JSON.stringify({ status: select.value })
        });
        showStatus("organizer-status", "Updated proposal status.", "success");
        await refreshOrganizerProposals();
      } catch (error) {
        showStatus("organizer-status", error.message, "error");
      }
    });

    editorForm.addEventListener("submit", async function (event) {
      event.preventDefault();
      var proposalID = editorForm.elements.proposalID.value;
      if (!proposalID) {
        showStatus("organizer-editor-status", "Choose a proposal first.", "error");
        return;
      }

      var payload = {
        conferenceId: editorForm.elements.conferenceId.value.trim(),
        title: editorForm.elements.title.value.trim(),
        titleJA: editorForm.elements.titleJA.value.trim(),
        abstract: editorForm.elements.abstract.value.trim(),
        abstractJA: editorForm.elements.abstractJA.value.trim(),
        talkDetail: editorForm.elements.talkDetail.value.trim(),
        talkDuration: editorForm.elements.talkDuration.value.trim(),
        speakerName: editorForm.elements.speakerName.value.trim(),
        speakerEmail: editorForm.elements.speakerEmail.value.trim(),
        bio: editorForm.elements.bio.value.trim(),
        bioJa: editorForm.elements.bioJa.value.trim(),
        jobTitle: editorForm.elements.jobTitle.value.trim(),
        jobTitleJa: editorForm.elements.jobTitleJa.value.trim(),
        githubUsername: editorForm.elements.githubUsername.value.trim(),
        iconURL: editorForm.elements.iconURL.value.trim(),
        notes: editorForm.elements.notes.value.trim()
      };
      if (payload.talkDuration === "workshop") {
        Object.assign(payload, readWorkshopPayload(editorForm, {
          coInstructorPrefixes: ["organizer-edit-co1", "organizer-edit-co2"],
          includeJapaneseFields: true
        }));
      }

      try {
        await apiRequest("/api/v1/admin/proposals/" + encodeURIComponent(proposalID), {
          method: "PUT",
          body: JSON.stringify(payload)
        });
        showStatus("organizer-editor-status", "Proposal updated.", "success");
        await refreshOrganizerProposals();
        loadOrganizerProposalIntoEditor(proposalID);
      } catch (error) {
        showStatus("organizer-editor-status", error.message, "error");
      }
    });

    deleteProposalButton.addEventListener("click", async function () {
      var proposalID = editorForm.elements.proposalID.value;
      if (!proposalID) {
        showStatus("organizer-editor-status", "Choose a proposal first.", "error");
        return;
      }

      try {
        await apiRequest("/api/v1/admin/proposals/" + encodeURIComponent(proposalID), {
          method: "DELETE"
        });
        showStatus("organizer-editor-status", "Proposal deleted.", "success");
        await refreshOrganizerProposals();
        resetOrganizerEditor();
      } catch (error) {
        showStatus("organizer-editor-status", error.message, "error");
      }
    });

    slotList.addEventListener("click", async function (event) {
      var editButton = event.target.closest("[data-edit-slot]");
      if (editButton) {
        loadSlotIntoEditor(editButton.getAttribute("data-edit-slot"));
        return;
      }

      var moveUpButton = event.target.closest("[data-move-slot-up]");
      if (moveUpButton) {
        moveSlot(moveUpButton.getAttribute("data-move-slot-up"), "up");
        return;
      }

      var moveDownButton = event.target.closest("[data-move-slot-down]");
      if (moveDownButton) {
        moveSlot(moveDownButton.getAttribute("data-move-slot-down"), "down");
        return;
      }

      var deleteButton = event.target.closest("[data-delete-slot]");
      if (!deleteButton) return;

      var slotID = deleteButton.getAttribute("data-delete-slot");
      if (!slotID) return;

      try {
        await apiRequest("/api/v1/admin/timetable/slots/" + encodeURIComponent(slotID), {
          method: "DELETE"
        });
        showStatus("organizer-timetable-status", "Timetable slot deleted.", "success");
        await refreshOrganizerSlots();
      } catch (error) {
        showStatus("organizer-timetable-status", error.message, "error");
      }
    });

    slotEditorForm.addEventListener("submit", async function (event) {
      event.preventDefault();
      var slotID = slotEditorForm.elements.slotID.value;
      if (!slotID) {
        showStatus("organizer-slot-editor-status", "Choose a slot first.", "error");
        return;
      }

      var payload = {
        day: Number(slotEditorForm.elements.day.value),
        slotType: slotEditorForm.elements.slotType.value
      };
      var proposalId = slotEditorForm.elements.proposalId.value.trim();
      var place = slotEditorForm.elements.place.value.trim();
      var startTime = toISODateTime(slotEditorForm.elements.startTime.value);
      var endTime = toISODateTime(slotEditorForm.elements.endTime.value);
      var customTitle = slotEditorForm.elements.customTitle.value.trim();
      payload.proposalId = proposalId ? proposalId : null;
      payload.place = place ? place : null;
      payload.startTime = startTime || null;
      payload.endTime = endTime || null;
      payload.customTitle = customTitle ? customTitle : null;

      try {
        await apiRequest("/api/v1/admin/timetable/slots/" + encodeURIComponent(slotID), {
          method: "PUT",
          body: JSON.stringify(payload)
        });
        showStatus("organizer-slot-editor-status", "Slot updated.", "success");
        await refreshOrganizerSlots();
        loadSlotIntoEditor(slotID);
      } catch (error) {
        showStatus("organizer-slot-editor-status", error.message, "error");
      }
    });

    slotReorderButton.addEventListener("click", async function () {
      var slotID = slotEditorForm.elements.slotID.value;
      if (!slotID) {
        showStatus("organizer-slot-editor-status", "Choose a slot first.", "error");
        return;
      }

      var day = Number(slotEditorForm.elements.day.value);
      var sameDay = state.organizerSlots
        .filter(function (item) { return item.day === day; })
        .sort(function (lhs, rhs) { return lhs.sortOrder - rhs.sortOrder; })
        .map(function (item, index) {
          return { id: item.id, sortOrder: index };
        });

      try {
        await apiRequest("/api/v1/admin/timetable/reorder", {
          method: "POST",
          body: JSON.stringify(sameDay)
        });
        showStatus("organizer-slot-editor-status", "Day order saved.", "success");
        await refreshOrganizerSlots();
      } catch (error) {
        showStatus("organizer-slot-editor-status", error.message, "error");
      }
    });

    workshopList.addEventListener("click", async function (event) {
      var capacityButton = event.target.closest("[data-save-workshop-capacity]");
      if (capacityButton) {
        var registrationID = capacityButton.getAttribute("data-save-workshop-capacity");
        var capacityInput = workshopList.querySelector('[data-workshop-capacity="' + registrationID + '"]');
        if (!registrationID || !capacityInput) return;

        try {
          await apiRequest("/api/v1/admin/workshops/" + encodeURIComponent(registrationID) + "/capacity", {
            method: "PUT",
            body: JSON.stringify({ capacity: Number(capacityInput.value) })
          });
          showStatus("organizer-workshops-status", "Capacity updated.", "success");
          await refreshOrganizerWorkshops();
        } catch (error) {
          showStatus("organizer-workshops-status", error.message, "error");
        }
        return;
      }

      var lumaButton = event.target.closest("[data-save-workshop-luma]");
      if (lumaButton) {
        var lumaRegistrationID = lumaButton.getAttribute("data-save-workshop-luma");
        var lumaInput = workshopList.querySelector('[data-workshop-luma-event="' + lumaRegistrationID + '"]');
        if (!lumaRegistrationID || !lumaInput) return;

        try {
          await apiRequest("/api/v1/admin/workshops/" + encodeURIComponent(lumaRegistrationID) + "/luma-event", {
            method: "PUT",
            body: JSON.stringify({ lumaEventID: lumaInput.value.trim() || null })
          });
          showStatus("organizer-workshops-status", "Luma event ID updated.", "success");
          await refreshOrganizerWorkshops();
        } catch (error) {
          showStatus("organizer-workshops-status", error.message, "error");
        }
        return;
      }

      var createLumaButton = event.target.closest("[data-create-workshop-luma]");
      if (!createLumaButton) return;

      var createRegistrationID = createLumaButton.getAttribute("data-create-workshop-luma");
      if (!createRegistrationID) return;

      try {
        var createResponse = await apiRequest("/api/v1/admin/workshops/" + encodeURIComponent(createRegistrationID) + "/create-luma-event", {
          method: "POST"
        });
        showStatus("organizer-workshops-status", createResponse.message || "Luma event created.", "success");
        await refreshOrganizerWorkshops();
      } catch (error) {
        showStatus("organizer-workshops-status", error.message, "error");
      }
    });

    workshopApplicationsList.addEventListener("click", async function (event) {
      var deleteButton = event.target.closest("[data-delete-workshop-application]");
      if (!deleteButton) return;
      var applicationID = deleteButton.getAttribute("data-delete-workshop-application");
      if (!applicationID) return;

      try {
        await apiRequest("/api/v1/admin/workshop-applications/" + encodeURIComponent(applicationID), {
          method: "DELETE"
        });
        showStatus("organizer-workshop-applications-status", "Workshop application deleted.", "success");
        await refreshOrganizerWorkshopApplications();
      } catch (error) {
        showStatus("organizer-workshop-applications-status", error.message, "error");
      }
    });

    workshopLotteryButton.addEventListener("click", async function () {
      try {
        var lottery = await apiRequest("/api/v1/admin/workshops/lottery", { method: "POST" });
        showStatus("organizer-workshops-status", "Lottery complete: " + lottery.assigned + " assigned, " + lottery.unassigned + " unassigned.", "success");
        await refreshOrganizerWorkshops();
        await refreshOrganizerWorkshopApplications();
        await refreshOrganizerWorkshopResults();
      } catch (error) {
        showStatus("organizer-workshops-status", error.message, "error");
      }
    });

    workshopSendTicketsButton.addEventListener("click", async function () {
      try {
        var ticketResponse = await apiRequest("/api/v1/admin/workshops/send-tickets", { method: "POST" });
        showStatus("organizer-workshops-status", "Tickets sent: " + ticketResponse.sent + " success, " + ticketResponse.skipped + " skipped, " + ticketResponse.errors + " errors.", "success");
        await refreshOrganizerWorkshops();
        await refreshOrganizerWorkshopResults();
      } catch (error) {
        showStatus("organizer-workshops-status", error.message, "error");
      }
    });

    await refreshOrganizerProposals();
    await refreshOrganizerSlots();
    await refreshOrganizerWorkshops();
    await refreshOrganizerWorkshopApplications();
    await refreshOrganizerWorkshopResults();
    resetOrganizerEditor();
    resetSlotEditor();
    var initialProposalID = extractOrganizerProposalRouteID();
    if (initialProposalID) {
      loadOrganizerProposalIntoEditor(initialProposalID);
    }
  }

  async function bootstrapPage() {
    var path = normalizedPathname();

    if (path === "/profile") {
      await bootstrapProfilePage();
      return;
    }
    if (path === "/submit") {
      await bootstrapSubmitPage();
      return;
    }
    if (path === "/workshops") {
      await bootstrapWorkshopsPage();
      return;
    }
    if (path === "/my-proposals" || path.indexOf("/my-proposals/") === 0) {
      await bootstrapMyProposalsPage();
      return;
    }
    if (path === "/organizer" || path.indexOf("/organizer/") === 0) {
      await bootstrapOrganizerPage();
      return;
    }
    if (path === "/feedback") {
      await bootstrapFeedbackPage();
    }
  }

  async function bootstrap() {
    wireLogin();
    wireLogout();

    try {
      state.user = await apiRequest("/api/v1/auth/me");
      updateAuthState(state.user);
    } catch (_error) {
      state.user = null;
      updateAuthState(null);
    }

    await bootstrapPage();
  }

  window.addEventListener("DOMContentLoaded", bootstrap);
})();
