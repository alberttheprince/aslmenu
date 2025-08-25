let isOpen = false;
let inputReady = false;
let isThirdPersonMode = false;
let isTyping = false;

window.addEventListener('message', (event) => {
    if (event.data.type === 'showASLInput') {
        showInput(event.data.persistent, event.data.thirdPerson);
    } else if (event.data.type === 'hideASLInput') {
        hideInput();
    } else if (event.data.type === 'updateStatus') {
        updateStatus(event.data.status);
    } else if (event.data.type === 'focusInput') {
        focusInput();
    } else if (event.data.type === 'blurInput') {
        blurInput();
    }
});

function showInput(persistent, thirdPerson) {
    isOpen = true;
    inputReady = false;
    isThirdPersonMode = thirdPerson || false;
    isTyping = !isThirdPersonMode; // Only typing immediately if not third-person
    
    document.getElementById('asl-container').style.display = 'block';
    document.getElementById('asl-input').value = '';
    
    // Update hint based on mode
    const hintElement = document.querySelector('.hint');
    if (isThirdPersonMode) {
        hintElement.textContent = "Press ENTER to type | Press ESC to exit";
        document.getElementById('asl-input').blur(); // Don't focus initially
    } else {
        hintElement.textContent = "Press ENTER to sign | Press ESC to close";
        document.getElementById('asl-input').focus();
    }
    
    // Wait a bit before accepting input
    setTimeout(() => {
        inputReady = true;
    }, 200);
}

function hideInput() {
    isOpen = false;
    inputReady = false;
    isThirdPersonMode = false;
    isTyping = false;
    document.getElementById('asl-container').style.display = 'none';
    document.getElementById('asl-input').blur();
    document.getElementById('status-display').textContent = '';
    document.querySelector('.input-wrapper').classList.remove('typing-active');
    document.querySelector('.hint').classList.remove('active');
}

function updateStatus(status) {
    document.getElementById('status-display').textContent = status;
}

function focusInput() {
    if (isThirdPersonMode) {
        isTyping = true;
        document.getElementById('asl-input').focus();
        document.querySelector('.hint').textContent = "Type your message | Press ENTER to sign | Press ESC to stop typing";
        document.querySelector('.input-wrapper').classList.add('typing-active');
        document.querySelector('.hint').classList.add('active');
    }
}

function blurInput() {
    if (isThirdPersonMode) {
        isTyping = false;
        document.getElementById('asl-input').blur();
        document.querySelector('.hint').textContent = "Press ENTER to type | Press ESC to exit";
        document.querySelector('.input-wrapper').classList.remove('typing-active');
        document.querySelector('.hint').classList.remove('active');
    }
}

// Global keydown listener for Escape key and Enter in third-person mode
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && isOpen) {
        e.preventDefault();
        
        // In third-person mode, ESC either stops typing or closes ASL
        if (isThirdPersonMode && isTyping) {
            // Just stop typing, don't close ASL
            fetch(`https://aslmenu/releaseThirdPersonFocus`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            blurInput();
        } else {
            // Close ASL completely
            fetch(`https://aslmenu/closeASL`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            hideInput();
        }
    }
    
    // Handle Enter key for activating input in third-person mode
    if (e.key === 'Enter' && isOpen && isThirdPersonMode && !isTyping) {
        e.preventDefault();
        // The Lua script will handle this via control detection
        // We just need to be ready to receive the focus message
    }
});

// Input-specific listener for Enter key and text submission
document.getElementById('asl-input').addEventListener('keydown', (e) => {
    if (!inputReady) return;
    
    if (e.key === 'Enter') {
        e.preventDefault();
        const text = e.target.value.trim();
        
        if (text.length > 0) {
            // Submit text but don't hide input
            fetch(`https://aslmenu/submitASLText`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text: text })
            });
            
            // Clear input for next entry
            e.target.value = '';
            
            // In third-person mode, release focus after submitting
            if (isThirdPersonMode) {
                blurInput();
            }
        }
    }
});