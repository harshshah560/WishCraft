
document.addEventListener("DOMContentLoaded", async () => {
  const status = document.getElementById("status");
  const wishlistSelect = document.getElementById("wishlist");

  // Prefill product name
  let [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  document.getElementById("name").value = tab.title;
  console.log("🔥 ABOUT TO FETCH WISHLISTS");
  // Fetch wishlists
 try {
  const res = await fetch("http://localhost:6521/getWishlists");

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`HTTP ${res.status}: ${errText}`);
  }

  const wishlists = await res.json();

  if (!Array.isArray(wishlists)) throw new Error("Response was not an array");

  wishlists.forEach(w => {
    const option = document.createElement("option");
    option.value = w.id;
    option.textContent = w.name;
    wishlistSelect.appendChild(option);
  });

  console.log("✅ Wishlists loaded into dropdown.");
} catch (e) {
  status.textContent = "⚠️ Could not load wishlists.";
  console.error("Wishlist load error:", e);
}


  document.getElementById("saveBtn").addEventListener("click", async () => {
    const name = document.getElementById("name").value;
    const notes = document.getElementById("notes").value;
    const wishlistId = wishlistSelect.value;

    const body = {
      wishlistId,
      name,
      link: tab.url,
      notes
    };

    status.textContent = "⏳ Sending...";

    try {
      const res = await fetch("http://localhost:6521/addItem", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
      });

      if (res.ok) {
        status.textContent = "✅ Item added to WishCraft!";
      } else {
        const errText = await res.text();
        status.textContent = `❌ Server error: ${errText}`;
      }
    } catch (e) {
      status.textContent = "⚠️ Could not reach WishCraft.";
      console.error("POST error:", e);
    }
  });
});
