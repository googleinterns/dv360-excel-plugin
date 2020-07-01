/// Manual testing instructions for Excel spreadsheet population functionalities
///
/// Steps:
/// * Serve the web app on localhost: 8080.
/// * Verify that web app is running on http://localhost:8080/.
/// * Sideload the add-in following the instructions
///   [here](https://docs.microsoft.com/en-us/office/dev/add-ins/testing/test-debug-office-add-ins).
/// * On Excel, go to Insert, My Add-ins (on the ribbon), and select DV360.
/// * Click on sign-in and allows the web app to access DV360 data.
/// * Enter an valid advertiserId and insertionOrderId combo.
/// * Click on populate
///
/// Expected Result:
/// * Should see a new sheet getting created that contains a table of insertion orders.
/// * Insertion order data values should match with those on the DV360 UI.
