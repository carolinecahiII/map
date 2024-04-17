import processing.data.*; // Import the Processing data library to handle JSON

JSONObject json; // Declare a JSONObject to hold the data
PImage mapImage;
HashMap<Integer, String> colorToRegionMap = new HashMap<>();
String selectedRegionName = ""; // Variable to store the name of the selected region
String frozenRegionName = ""; // Variable to store the name of the frozen region

// Dropdown menu for season selection
String[] seasons = {"Spring", "Summer", "Fall", "Winter", "All Seasons"};
String selectedSeason = "All Seasons"; // Default selection
boolean dropdownExpanded = false;
float dropdownX; // X position of the dropdown, set in setup()
float dropdownY = 40; // Y position of the dropdown, set below the region name
float dropdownWidth = 260; // Width of the dropdown
float dropdownHeight = 20; // Height of each dropdown item

float zoom = .2; // Default zoom level
float minZoom = 0.2; // Minimum zoom level
float maxZoom = 1; // Maximum zoom level

float posX, posY; // Position of the map image
float prevMouseX, prevMouseY; // Previous mouse position for dragging

float scrollY = 0; // Scroll offset
float maxScrollY = 0; // Maximum scroll offset, to be calculated

// Global variables for close button
float closeButtonX, closeButtonY;
float closeButtonSize = 20;

boolean showPopup = false; // Flag to indicate whether to show the pop-up
ForageableItem popupItem = null; // The item to show in the pop-up

int dropdownButtonColor = color(100, 149, 237); 
String dropdownLabel = "Sort by Season";

ArrayList<ForageableItem> displayedItems = new ArrayList<ForageableItem>(); // List to hold displayed items

void setup() {
  size(1260, 940);
  mapImage = loadImage("genius.png");
  initializeColorToRegionMap(); // Initialize the mapping from color to region
  json = loadJSONObject("data/taxonomy.json"); // Load the JSON file

  // Center the image on the screen
  posX = (width - mapImage.width * zoom) * 0.5;
  posY = (height - mapImage.height * zoom) * 0.5;

  // Set the position for the dropdown
    dropdownX = width - dropdownWidth - 15; // 20 pixels from the right edge of the sidebar
}

void draw() {
  background(0);
  pushMatrix();
  translate(posX, posY);
  scale(zoom);
  image(mapImage, 0, 0);
  popMatrix();

  drawSidebar();
  
  // Check for the region under the mouse
  String hoverRegion = detectRegionByColor();
  if (!hoverRegion.equals("")) {
    int itemCount = countItemsForRegion(hoverRegion);
    fill(255);
    textSize(16);
    text(hoverRegion + " - " + itemCount + " Forageable Items", 20, height - 20);
  }
  
  // If an item is clicked, draw the popup
  if (showPopup && popupItem != null) {
    drawPopup(popupItem);
  }
}
void drawSidebar() {
  fill(240);
  noStroke();
  rect(width - 280, 0, 280, height); // Sidebar

  fill(255);
  rect(width - 280, 0, 280, 30); // Top bar

  // Draw the region name in the top bar
  String regionName = frozenRegionName.isEmpty() ? selectedRegionName : frozenRegionName;
  fill(0);
  textSize(18);
  textAlign(CENTER, CENTER);
  text(regionName, width - 140, 15); // Centered region name
  
  // Draw the dropdown menu for season selection
  drawDropdown();

  // "Clear Selection" button
  fill(255, 0, 0);
  rect(width - 250, height - 50, 200, 40); // Button
  fill(255);
  textSize(16);
  textAlign(CENTER, CENTER);
  text("Clear Selection", width - 150, height - 30);

  // Items list
  textAlign(LEFT, TOP); // Align text to the left
  float startY = dropdownY + (dropdownExpanded ? dropdownHeight * seasons.length : dropdownHeight) + 10; // Start below the dropdown
  float y = startY - scrollY;
  textSize(16);
  maxScrollY = 0; // Reset max scroll each frame

  for (ForageableItem item : displayedItems) {
    if (itemSeasonMatches(item, selectedSeason)) {
      float itemX = width - 280 + 10; // Sidebar padding
      if (y + 20 < height - 50) { // Ensure items don't draw over the clear button
        fill(0); // Black color for text
        text(item.commonName, itemX, y); // Draw item name
        y += 20; // Move down for the next item
      }
      maxScrollY += 20; // Increment max scroll for each item
    }
  }

  scrollY = constrain(scrollY, 0, maxScrollY - (height - startY - 50)); // Update maxScrollY to constrain the scroll correctly
}

void drawDropdown() {
  // Draw the button with the label
  fill(dropdownButtonColor); // Cornflower Blue background for the button
  rect(dropdownX, dropdownY, dropdownWidth, dropdownHeight);
  
  // Center text alignment for the dropdown label
  fill(255); // White text
  textAlign(CENTER, CENTER); // Center the text horizontally and vertically
  text(dropdownLabel, dropdownX + dropdownWidth/2, dropdownY + dropdownHeight/2); // Position the text in the center of the button

  if (dropdownExpanded) {
    textAlign(LEFT, CENTER); // Align text to the left for the dropdown items
    // Draw the dropdown items
    for (int i = 0; i < seasons.length; i++) {
      float itemY = dropdownY + dropdownHeight * (i + 1); // Position items below the button
      fill(255); // Background color for items
      rect(dropdownX, itemY, dropdownWidth, dropdownHeight);
      fill(0); // Text color
      text(seasons[i], dropdownX + 5, itemY + dropdownHeight/2); // Draw the text aligned to the left
    }
  }
  // Reset textAlign to default for other drawing operations if needed
  textAlign(LEFT, BASELINE);
}


String detectRegionByColor() {
  int adjustedX = (int)((mouseX - posX) / zoom);
  int adjustedY = (int)((mouseY - posY) / zoom);

  if (adjustedX >= 0 && adjustedX < mapImage.width && adjustedY >= 0 && adjustedY < mapImage.height) {
    int colorUnderMouse = mapImage.get(adjustedX, adjustedY);
    if (colorToRegionMap.containsKey(colorUnderMouse)) {
      selectedRegionName = colorToRegionMap.get(colorUnderMouse);
      return selectedRegionName;
    }
  }
  return ""; // Return empty if no region is detected
}


float drawWrappedText(String text, float x, float y, float boxWidth, float lineHeight) {
  String[] words = text.split(" ");
  String line = "";
  float startY = y;
  for (String word : words) {
    // Check if adding another word exceeds the line width
    if (textWidth(line + word) < boxWidth) {
      line += word + " ";
    } else {
      // Draw the line if it's within the sidebar bounds
      if (y > 0 && y < height - 50) { // Adjust the lower bound if needed
        text(line, x, y);
      }
      line = word + " ";
      y += lineHeight;
    }
  }
  // Draw the remaining text
  if (y > 0 && y < height - 50) { // Adjust the lower bound if needed
    text(line, x, y);
  }
  return y - startY + lineHeight; // Return the height of the text block
}


void initializeColorToRegionMap() {
  // Initialize your color to region mapping here
  // Correct the color format to match Processing's color format
  colorToRegionMap.put(color(#8d9267), "North Maine");
  colorToRegionMap.put(color(#dfe3bb), "Maine Coast");
  colorToRegionMap.put(color(#6f7729), "Maine West");
  colorToRegionMap.put(color(#a7b33e), "Maine South");

  colorToRegionMap.put(color(#e2dcda), "New Hampshire North");
  colorToRegionMap.put(color(#b7948b), "New Hampshire South");
  colorToRegionMap.put(color(#8a9eba), "Vermont North");
  colorToRegionMap.put(color(#576c8b), "Vermont South");

  colorToRegionMap.put(color(#1f4c09), "Western Mass");
  colorToRegionMap.put(color(#45782c), "Northampton Area");
  colorToRegionMap.put(color(#65964c), "Worcester Area");
  colorToRegionMap.put(color(#5d8e63), "Boston Area");
  colorToRegionMap.put(color(#9ec48a), "North Shore MA");
  colorToRegionMap.put(color(#9ec48a), "South Shore MA");
  colorToRegionMap.put(color(#ccf1d0), "Cape and Islands");

  colorToRegionMap.put(color(#383d39), "Rhode Island");

  colorToRegionMap.put(color(#93561a), "Connecticut East");
  colorToRegionMap.put(color(#ac723b), "Connecticut Central");
  colorToRegionMap.put(color(#b88c61), "Connecticut West");
}
void selectRegion(String regionName) {
  // Update the list of items only if a new region is selected
  if (!frozenRegionName.equals(regionName)) {
    frozenRegionName = regionName; // Set the frozen region to the newly clicked region
    noLoop(); // Disable drawing loop to update displayedItems
    displayedItems = findItemsForRegion(frozenRegionName); // Update the items displayed
    scrollY = 0; // Reset scroll position
    maxScrollY = calculateMaxScrollY(); // You need to implement calculateMaxScrollY()
    loop(); // Re-enable the drawing loop
  }
}
int calculateMaxScrollY() {
  return displayedItems.size() * 20; // Assuming each item is 20 pixels in height
}

void mousePressed() {
  prevMouseX = mouseX;
  prevMouseY = mouseY;

  // Dropdown logic
  if (mouseX > dropdownX && mouseX < dropdownX + dropdownWidth &&
      mouseY > dropdownY && mouseY < dropdownY + dropdownHeight) {
    dropdownExpanded = !dropdownExpanded;
  } else if (dropdownExpanded) {
    int selectedIndex = (int) ((mouseY - dropdownY - dropdownHeight) / dropdownHeight);
    if (selectedIndex >= 0 && selectedIndex < seasons.length) {
      selectedSeason = seasons[selectedIndex];
      dropdownLabel = "Sort by: " + selectedSeason;
      dropdownExpanded = false;
    }
  } else if (dropdownExpanded && (mouseY < dropdownY || mouseY > dropdownY + dropdownHeight * seasons.length)) {
    dropdownExpanded = false;
  }

  // Clear selection button logic
  if (mouseX > width - 250 && mouseX < width - 50 && mouseY > height - 50 && mouseY < height) {
    frozenRegionName = "";
    displayedItems.clear();
    showPopup = false;
    popupItem = null;
    scrollY = 0;
  } else {
    String clickedRegion = detectRegionByColor();
    if (!clickedRegion.equals("")) {
      selectRegion(clickedRegion);
    }
  }
}

boolean itemSeasonMatches(ForageableItem item, String season) {
  // Logic to determine if the item's season matches the selected season

  String itemSeason = getSeasonText(item.details);
  return season.equals("All Seasons") || itemSeason.contains(season);
}
// Helper function to get the season text from the details JSONObject
String getSeasonText(JSONObject details) {
  String seasonText = "";
  if (details.hasKey("season")) {
    Object seasonObj = details.get("season");
    if (seasonObj instanceof String) {
      seasonText = (String) seasonObj;
    } else if (seasonObj instanceof JSONArray) {
      JSONArray seasons = (JSONArray) seasonObj;
      for (int i = 0; i < seasons.size(); i++) {
        if (i > 0) seasonText += ", ";
        seasonText += seasons.getString(i);
      }
    } else {
      seasonText = "Unknown"; // Default text if "season" is neither a string nor an array
    }
  }
  return seasonText;
}

void drawPopup(ForageableItem item) {
  float padding = 20;
  
  // Set text size for calculating widths and heights
  textSize(16);
  float textHeight = textAscent() + textDescent();
  
  // Calculate the width of the text based on the longest line
  String commonNameText = "Common Name: " + item.commonName;
  String typeText = "Type: " + item.details.getString("type");
  String seasonText = "Season: " + getSeasonText(item.details);
  float textWidth = max(textWidth(commonNameText), max(textWidth(typeText), textWidth(seasonText)));
  
  // Calculate the total width and height of the popup
  float popupWidth = textWidth + (padding * 2);
  float popupHeight = textHeight * 6 + padding * 2; // Height for three lines of text
  
  // Set the position for the popup
  float popupX = 300;
  float popupY = 200;

  // Draw popup background
  fill(255);
  rect(popupX, popupY, popupWidth, popupHeight);
  
  // Draw the close button at the top right
  closeButtonX = popupX + popupWidth - closeButtonSize - padding;
  closeButtonY = popupY + padding;
  fill(255, 0, 0);
  rect(closeButtonX, closeButtonY, closeButtonSize, closeButtonSize);
  fill(255);
  textSize(14);
  textAlign(CENTER, CENTER);
  text("X", closeButtonX + closeButtonSize / 2, closeButtonY + closeButtonSize / 2);
  
  // Reset text size and alignment for content
  textSize(16);
  textAlign(LEFT, TOP);
  
  // Draw the text content below the close button
  float textX = popupX + padding;
  float textY = closeButtonY + closeButtonSize + padding; // Start text below the close button
  
  fill(0);
  text(commonNameText, textX, textY);
  textY += textHeight;
  text(typeText, textX, textY);
  textY += textHeight;
  text(seasonText, textX, textY);
  
  // Reset textAlign to default for other drawing operations
  textAlign(LEFT, BASELINE);
}



void mouseDragged() {
  float dx = mouseX - prevMouseX;
  float dy = mouseY - prevMouseY;
  posX += dx;
  posY += dy;
  prevMouseX = mouseX;
  prevMouseY = mouseY;
}
void mouseClicked() {
    if (mouseX >= closeButtonX && mouseX < closeButtonX + closeButtonSize &&
      mouseY >= closeButtonY && mouseY < closeButtonY + closeButtonSize) {
    // If so, close the popup and clear the current item
    showPopup = false;
    popupItem = null;
  }
}


void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  // Check if the mouse is over the sidebar
  boolean overSidebar = mouseX >= width - 280;

  if (overSidebar) {
    // Only scroll the sidebar content if we are over the sidebar
    scrollY -= 10 * e;
    scrollY = constrain(scrollY, 0, maxScrollY);
  } else {
    // Zoom the map only if we are not over the sidebar
    zoom *= 1 - 0.05 * e;
    zoom = constrain(zoom, minZoom, maxZoom);

    // Adjust map position based on zoom to keep it centered
    posX = (width - mapImage.width * zoom) * 0.5;
    posY = (height - mapImage.height * zoom) * 0.5;
  }
}




ArrayList<ForageableItem> findItemsForRegion(String regionName) {
  ArrayList<ForageableItem> items = new ArrayList<ForageableItem>();
  JSONArray forageableItems = json.getJSONArray("forageableItems");
  for (int i = 0; i < forageableItems.size(); i++) {
    JSONObject item = forageableItems.getJSONObject(i);
    if (item.hasKey("regions")) {
      JSONArray regions = item.getJSONArray("regions");
      for (int j = 0; j < regions.size(); j++) {
        if (regions.getString(j).equals(regionName)) {
          items.add(new ForageableItem(item.getString("commonName"), item));
          break;
        }
      }
    }
  }
  return items;
}

class ForageableItem {
  String commonName;
  JSONObject details;
  boolean showDetails = false;
  float x, y, width, height; // Bounding box properties

  void setBoundingBox(float x, float y, float width, float height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  boolean isMouseOver(float mouseX, float mouseY) {
    return mouseX >= x && mouseX <= x + width && mouseY >= y && mouseY <= y + height;
  }
  ForageableItem(String commonName, JSONObject details) {
    this.commonName = commonName;
    this.details = details;
  }
}
int countItemsForRegion(String regionName) {
  JSONArray forageableItems = json.getJSONArray("forageableItems");
  int count = 0;
  for (int i = 0; i < forageableItems.size(); i++) {
    JSONObject item = forageableItems.getJSONObject(i);
    if (item.hasKey("regions")) {
      JSONArray regions = item.getJSONArray("regions");
      for (int j = 0; j < regions.size(); j++) {
        if (regions.getString(j).equals(regionName)) {
          count++;
          break; // Stop checking this item if the region matches
        }
      }
    }
  }
  return count;
}
