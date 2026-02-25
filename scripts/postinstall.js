#!/usr/bin/env node

const RESET = "\x1b[0m";
const BOLD = "\x1b[1m";
const CYAN = "\x1b[36m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";

console.log(`
${BOLD}${CYAN}EVC Mesh OpenClaw Skill${RESET} installed successfully.

${BOLD}Quick Setup:${RESET}

${GREEN}1.${RESET} Set your agent key (get it from EVC Mesh admin panel):
   ${YELLOW}export MESH_AGENT_KEY="agk_your_workspace_key_here"${RESET}

${GREEN}2.${RESET} Register the MCP server with OpenClaw (stdio mode):
   ${YELLOW}openclaw mcp add --name evc-mesh --from "$(npm root -g)/@entire-vc/evc-mesh-openclaw-skill/config/openclaw-mcp-stdio.json"${RESET}

   Or for SSE mode (remote MCP server):
   ${YELLOW}openclaw mcp add --name evc-mesh --from "$(npm root -g)/@entire-vc/evc-mesh-openclaw-skill/config/openclaw-mcp-sse.json"${RESET}

${GREEN}3.${RESET} Install skills:
   ${YELLOW}openclaw skill install "$(npm root -g)/@entire-vc/evc-mesh-openclaw-skill/skills/evc-mesh.md"${RESET}
   ${YELLOW}openclaw skill install "$(npm root -g)/@entire-vc/evc-mesh-openclaw-skill/skills/evc-mesh-events.md"${RESET}
   ${YELLOW}openclaw skill install "$(npm root -g)/@entire-vc/evc-mesh-openclaw-skill/skills/evc-mesh-coordination.md"${RESET}

${GREEN}4.${RESET} Verify MCP connection:
   ${YELLOW}openclaw mcp test evc-mesh${RESET}

${BOLD}Documentation:${RESET} https://github.com/entire-vc/evc-mesh-openclaw-skill
`);
