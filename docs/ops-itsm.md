# Operations and ITSM note

Not a ServiceNow product lab. This is how Monitor output is supposed to become a ticket.

## Why it is here

The resume work is Tier 2/3 in **ServiceNow**, with an availability target (90%+). Azure Monitor and Log Analytics are useless if nobody owns the page, the CI, or the post-incident note.

## Suggested ticket fields (identity or VPN incident)

| Field | Example |
| --- | --- |
| Category | Identity / Network |
| Configuration item | `lab-eus-hub-vnet` or `Conditional Access: MFA-privileged` |
| Impact / urgency | Map from alert severity (sev 0–4), do not invent SLAs in the ticket |
| Assignment group | Identity Ops or Network Ops |
| Short description | `VPN S2S tunnel down — lab-eus-hub-s2s` |
| Work notes | Alert rule name, KQL, first successful/failed probe, change window |

## Azure → ticket habit

1. Alert fires from Lab 05 action group (email / webhook — not a fake ServiceNow integration).
2. Operator runs the matching KQL in [labs/05-monitor-ops/queries](../labs/05-monitor-ops/queries).
3. If it is identity: Lab 01 audit script (standing Global Admin, Owner at subscription).
4. If it is path: Lab 04 DNS / NSG checks.
5. Close with: trigger, blast radius, change that fixed it, watch item.

## SLA mindset (honest)

A lab subscription will not demonstrate 90% availability. What you *can* show is:

- Alerts that page a human, not a dashboard nobody opens
- Queries that answer “is the tunnel up” and “who got Owner”
- A written IR path so the next person is not reconstructing chat history

See [labs/05-monitor-ops/README.md](../labs/05-monitor-ops/README.md).
