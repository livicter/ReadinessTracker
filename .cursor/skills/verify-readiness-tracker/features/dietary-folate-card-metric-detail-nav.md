# Dietary Folate → MetricDetail

Honest #435: body.folate.md.nav → MetricDetailView(.dietaryFolate).
Soft goal 400 mcg. Use lazy `NavigationLink { } label: { }` (eager destination
flaked on deep dietary cards). NavigationLink owns SurfaceID exclusively;
omit nested baseline/spark SurfaceIDs on chrome.
