import React, { useState } from "react";

const OPENROUTER_API_KEY = import.meta.env.VITE_OPENROUTER_API_KEY || "";

const Chatbot: React.FC = () => {
  const [messages, setMessages] = useState<string[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);

  const fetchResponse = async (message: string) => {
    try {
      setLoading(true);

      const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "mistralai/devstral-2512:free",
          messages: [
            { role: "user", content: message }
          ],
        }),
      });

      const result = await response.json();
      const responseText =
        result.choices?.[0]?.message?.content?.trim() || "Sorry, I couldn't understand.";

      setMessages((prev) => [
        ...prev,
        `User: ${message}`,
        `AI: ${responseText}`,
      ]);
    } catch (err) {
      console.error(err);
      setMessages((prev) => [...prev, "Error fetching response."]);
    }

    setLoading(false);
  };

  const handleSend = () => {
    if (!input.trim()) return;
    fetchResponse(input);
    setInput("");
  };

  return (
    <div style={{ padding: "20px", fontFamily: "Arial" }}>
      <h2>Chatbot</h2>

      <div
        style={{
          height: "300px",
          overflowY: "scroll",
          border: "1px solid black",
          padding: "10px",
        }}
      >
        {messages.map((msg, i) => (
          <p key={i}>{msg}</p>
        ))}
      </div>

      <input
        type="text"
        value={input}
        onChange={(e) => setInput(e.target.value)}
        style={{ width: "80%", padding: "10px", marginTop: "10px" }}
      />

      <button
        onClick={handleSend}
        style={{ padding: "10px", marginLeft: "10px" }}
      >
        {loading ? "Loading..." : "Send"}
      </button>
    </div>
  );
};

export default Chatbot;
