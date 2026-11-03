# Acknowledgments and Contributors

Argus could not exist without the people and models who worked on it, and the
open-source projects it stands on. Roles are written down here to reflect the
work actually done, not a single vague "AI assistance" line. This list is
updated as people contribute, not at release time.

## Design and Development

*   **Ronan Davalan** — Architect and arbiter. Author of the original production scripts (2024), product vision, scope decisions, validation and testing on real machines.
*   **Claude Code (Anthropic)** — Lead developer and engineer. SSH, Fail2Ban and CrowdSec collectors, daily chart rendering, `argus-doctor.sh`, the Debian package and the documentation.
*   **Gemini (Google)** — Synthesizer and strategic co-writer. Planning of on-demand multi-machine chart generation and framing of the project's purpose; its claims were cross-checked against the code.
*   **Gemini (Google), GLM-5.3-Flash Free and Gemini 4 Argon** — Graphic designers. The project's visual identity (mark, icon, favicon): Gemini proposed the first colored version, GLM-5.3-Flash Free added the notion of position that replaced the initial keyhole and drew the SVG, Gemini 4 Argon recentered and improved the final result. Adopted by Ronan Davalan on 2026-11-02.
*   **DeepSeek** — Field companion. Installed and configured the CrowdSec instance on a real server against which `collect-crowdsec.sh` was validated and corrected.
*   **DeepSeek Flash** — Site content in English, then the French, German and Spanish translations of the documentation, manual pages and site.
*   **Muse Spark 1.3 Contributor** — Site styling: integration of the logo, the favicon and the chart image.
*   **gd2:** Ronan Davalan's late brother. He taught Ronan Git and how to use it, advised on this project, and made the first outside edit to its README (2024-08-07).

## Heritage

Argus was built within the same working framework as Ronan Davalan's other
projects (a shared governance template and collaboration method). Models
mentioned only in that template are not credited here.

## Code and Documentation Contributors

People who contributed through pull requests or issues will be listed here.

*(No outside contribution yet — your name could be the first.)*
