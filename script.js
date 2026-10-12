
/* ============================================
   EDWARD RINGA DUME
   Cloud & DevOps Portfolio
   ============================================ */

document.addEventListener("DOMContentLoaded", () => {
    // 1. Dynamic copyright year
    const currentYear = document.getElementById("current-year");

    if (currentYear) {
        currentYear.textContent = new Date().getFullYear();
    }

    // 2. AWS server-side visitor counter
    const visitorCountElement = document.getElementById("visitor-count");

    if (visitorCountElement) {
        const apiUrl =
            "https://zt5zhcxm3h.execute-api.eu-north-1.amazonaws.com/count";

        visitorCountElement.textContent = "Loading...";

        visitorCountElement.title =
            "Visitor count retrieved from AWS DynamoDB.";

        fetch(apiUrl, { cache: "no-store" })
            .then((response) => {
                if (!response.ok) {
                    throw new Error(
                        `Visitor API returned HTTP ${response.status}`
                    );
                }

                return response.json();
            })
            .then((data) => {
                if (
                    typeof data.count !== "number" ||
                    !Number.isFinite(data.count)
                ) {
                    throw new Error("Invalid visitor count received.");
                }

                visitorCountElement.textContent =
                    data.count.toLocaleString();

                visitorCountElement.setAttribute(
                    "aria-label",
                    `${data.count} visits recorded by the server`
                );
            })
            .catch((error) => {
                visitorCountElement.textContent = "Unavailable";
                console.error("AWS visitor counter failed:", error);
            });
    }

    // 3. External links security
    document.querySelectorAll('a[target="_blank"]').forEach((link) => {
        link.setAttribute("rel", "noopener noreferrer");
    });

    // 4. Smooth in-page navigation
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

    // 5. Console welcome message
    console.log(
        "%cEdward Ringa Dume | Cloud & DevOps Engineer",
        "color: #2563eb; font-size: 16px; font-weight: bold;"
    );

    console.log(
        "Portfolio loaded successfully. AWS | Terraform | Docker | Kubernetes"
    );
});