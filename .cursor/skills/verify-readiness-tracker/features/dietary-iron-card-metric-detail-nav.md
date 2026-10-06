# Dietary Iron → MetricDetail

Honest #431: body.iron.nav → MetricDetailView(.dietaryIron).
SurfaceID string is `body.iron.nav` (not `body.iron.card`) — legacy id collision stole NavigationLink taps.
NavigationLink owns SurfaceID exclusively.
