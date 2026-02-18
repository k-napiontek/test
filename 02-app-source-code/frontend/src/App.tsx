import { useState } from 'react'

function App() {
  const [inputValue, setInputValue] = useState('');
  const [status, setStatus] = useState('');

  const handleSave = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setStatus('Zapisywanie...');

    try {
      // React wysyła POST do Backendu (nie do bazy!)
      // AWS ALB Ingress zadba o to, by ruch na /api/ trafił do kontenera z Go
      const response = await fetch('http://127.0.0.1:8080/api/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: inputValue }),
      });
      console.log(response, "test");
      
      if (response.ok) {
        setStatus('Zapisano pomyślnie w bazie!');
        setInputValue('');
      } else {
        setStatus('Błąd podczas zapisywania.');
      }
    } catch (error) {
      setStatus('Brak połączenia z backendem.');
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h2>Zapisz coś do bazy PostgreSQL</h2>
      <form onSubmit={handleSave}>
        <input 
          type="text" 
          value={inputValue} 
          onChange={(e) => setInputValue(e.target.value)} 
          placeholder="Wpisz wiadomość..."
          required
        />
        <button type="submit">Zapisz</button>
      </form>
      <p>{status}</p>
    </div>
  );
}

export default App
