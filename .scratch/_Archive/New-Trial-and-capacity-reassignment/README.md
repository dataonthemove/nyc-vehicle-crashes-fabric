# New trial and capacity reassignment

All four workspaces (Landing, Dev, Test and Prod) sat on a Fabric trial capacity expiring on 28 September 2026. After expiry, Fabric items become inaccessible, and OneLake data may be deleted seven days later. With only three days left, a fast, low-risk move was needed.

The workspaces were reassigned to a new trial capacity rather than rebuilt from ADO. Reassignment kept every physical ID, all OneLake data, Git bindings, the deployment pipeline and its rules, and connections; only the capacity ID changed. This avoided a full re-CDC and three stage reloads.
