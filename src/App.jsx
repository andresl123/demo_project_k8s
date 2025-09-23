import { useEffect, useState } from 'react'

function App() {
  const [message, setMessage] = useState('loading...')

  useEffect(() => {
    // thanks to the proxy, this hits http://localhost:8080/hello
    fetch('/api/hello')
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.text()
      })
      .then(setMessage)
      .catch((err) => setMessage(`Error: ${err.message}`))
  }, [])

  return (
    <div style={{ padding: 24, fontFamily: 'system-ui, sans-serif' }}>
      <h1>React ↔ Spring Boot</h1>
      <p><h2>Backend says:</h2> {message}</p>
    </div>
  )
}

export default App
