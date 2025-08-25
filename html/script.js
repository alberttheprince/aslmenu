let isOpen = false;
let inputReady = false;

window.addEventListener('message', (event) => {
    if (event.data.type === 'showASLInput') {
        showInput(event.data.persistent);
    } else if (event.data.type === 'hideASLInput') {
        hideInput();
    } else if (event.data.type === 'updateStatus') {
        updateStatus(event.data.status);
    }
});

function showInput(persistent) {
    isOpen = true;
    inputReady = false;
    document.getElementById('asl-container').style.display = 'block';
    document.getElementById('asl-input').value = '';
    document.getElementById('asl-input').focus();
    
    // Wait a bit before accepting input
    setTimeout(() => {
        inputReady = true;
    }, 200);
}

function hideInput() {
    isOpen = false;
    inputReady = false;
    document.getElementById('asl-container').style.display = 'none';
    document.getElementById('asl-input').blur();
    document.getElementById('status-display').textContent = '';
}

function updateStatus(status) {
    document.getElementById('status-display').textContent = status;
}

// Global keydown listener for Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && isOpen) {
        e.preventDefault();
        fetch(`https://aslmenu/closeASL`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        hideInput();
    }
});

// Input-specific listener for Enter key and text submission
document.getElementById('asl-input').addEventListener('keydown', (e) => {
    if (!inputReady) return;
    
    if (e.key === 'Enter') {
        e.preventDefault();
        const text = e.target.value.trim();
        
        // Check for exit command
        if (text.toLowerCase() === 'exit') {
            fetch(`https://aslmenu/closeASL`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            hideInput();
            return;
        }
        
        if (text.length > 0) {
            // Submit text but don't hide input
            fetch(`https://aslmenu/submitASLText`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text: text })
            });
            
            // Clear input for next entry
            e.target.value = '';
        }
    }
    // Removed Escape handling from here since it's now global
});