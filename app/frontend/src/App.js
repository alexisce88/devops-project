import React, { useEffect, useState } from 'react';
import './App.css';

const API_URL = '/api';

function App() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [newItemName, setNewItemName] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const fetchItems = async () => {
    try {
      const res = await fetch(`${API_URL}/items`);
      if (!res.ok) throw new Error(`HTTP error: ${res.status}`);
      const data = await res.json();
      setItems(data);
      setError(null);
    } catch (err) {
      setError(`Failed to load items: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchItems();
  }, []);

  const handleAddItem = async (e) => {
    e.preventDefault();
    if (!newItemName.trim()) return;
    setSubmitting(true);
    try {
      const res = await fetch(`${API_URL}/items`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: newItemName.trim() }),
      });
      if (!res.ok) throw new Error(`HTTP error: ${res.status}`);
      setNewItemName('');
      await fetchItems();
    } catch (err) {
      setError(`Failed to add item: ${err.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>DevOps Project</h1>
        <p>3-Tier Web Application | CI/CD Pipeline Demo</p>
      </header>

      <main className="App-main">
        <section className="add-item">
          <h2>Add Item</h2>
          <form onSubmit={handleAddItem}>
            <input
              type="text"
              value={newItemName}
              onChange={(e) => setNewItemName(e.target.value)}
              placeholder="Enter item name..."
              disabled={submitting}
              aria-label="Item name"
            />
            <button type="submit" disabled={submitting || !newItemName.trim()}>
              {submitting ? 'Adding...' : 'Add Item'}
            </button>
          </form>
        </section>

        <section className="items-list">
          <h2>Items</h2>
          {loading && <p>Loading...</p>}
          {error && <p className="error" role="alert">{error}</p>}
          {!loading && !error && items.length === 0 && <p>No items found.</p>}
          {!loading && !error && items.length > 0 && (
            <ul>
              {items.map((item) => (
                <li key={item.id}>
                  <span className="item-name">{item.name}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  );
}

export default App;
