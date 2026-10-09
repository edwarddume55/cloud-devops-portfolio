
/* ============================================
   EDWARD RINGA DUME
   Cloud & DevOps Portfolio
   ============================================ */

document.addEventListener("DOMContentLoaded", () => {
    // --------------------------------------------
    // 1. Dynamic copyright year
    // --------------------------------------------

    const currentYear = document.getElementById("current-year");

    if (currentYear) {
        currentYear.textContent = new Date().getFullYear();
    }


    // --------------------------------------------
    // 2. Local visitor counter
    // --------------------------------------------
    // Counts visits in this browser only.
    // This is not a shared or server-side counter.

    const visitorCountElement = document.getElementById("visitor-count");

    if (visitorCountElement) {
        const storageKey = "edwardPortfolioVisitCount";
        const sessionKey = "edwardPortfolioVisitedThisSession";

        try {
            let visitCount = Number(localStorage.getItem(storageKey)) || 0;

            // Count one visit per browser session.
            if (!sessionStorage.getItem(sessionKey)) {
                visitCount += 1;

                localStorage.setItem(storageKey, String(visitCount));
                sessionStorage.setItem(sessionKey, "true");
            }

            visitorCountElement.textContent = visitCount.toLocaleString();
            visitorCountElement.title =
                "Local browser count, not total website visitors.";

            visitorCountElement.setAttribute(
                "aria-label",
                `${visitCount} visits recorded in this browser`
            );

        } catch (error) {
            // Storage may be unavailable in private or restricted browsing.
            visitorCountElement.textContent = "Unavailable";
            console.warn("Visitor counter storage is unavailable.", error);
        }
    }


    // --------------------------------------------
    // 3. External links security
    // --------------------------------------------

    document.querySelectorAll('a[target="_blank"]').forEach((link) => {
        link.setAttribute("rel", "noopener noreferrer");
    });


    // --------------------------------------------
    // 4. Smooth in-page navigation
    // --------------------------------------------
    // Applies to links that point to sections on this page.

    document.querySelectorAll('a[href^="#"]').forEach((link) => {
        link.addEventListener("click", (event) => {
            const targetId = link.getAttribute("href");

            if (!targetId || targetId === "#") {
                return;
            }

            const target = document.querySelector(targetId);

            if (target) {
                event.preventDefault();

                target.scrollIntoView({
                    behavior: window.matchMedia(
                        "(prefers-reduced-motion: reduce)"
                    ).matches ? "auto" : "smooth",
                    block: "start"
                });
            }
        });
    });


    // --------------------------------------------
    // 5. Console welcome message
    // --------------------------------------------

    console.log(
        "%cEdward Ringa Dume | Cloud & DevOps Engineer",
        "color: #2563eb; font-size: 16px; font-weight: bold;"
    );

    console.log(
        "Portfolio loaded successfully. AWS | Terraform | Docker | Kubernetes"
    );
});