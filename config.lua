Config = {}

-- Commands
-- /asl - Opens text prompt for signing in ASL (or /asl [text] to sign directly)
-- /aslhelp - Shows all available commands and how the system works
-- /asldebug - Toggles debug mode to show animation details in console (useful for troubleshooting)
-- /asltest - Toggles test mode to allow signing without nearby players (useful for testing alone)
-- Press X - Stops signing at any time

-- Animation definitions with both dictionary and animation name
-- Each animation requires: dict (animation dictionary) and name (animation clip name)

-- Letter animations
Config.LetterAnimations = {
    ["a"] = { dict = "asl_a@francis", name = "asl_a_clip" },
    ["b"] = { dict = "asl_b@francis", name = "asl_b_clip" },
    ["c"] = { dict = "asl_c@francis", name = "asl_c_clip" },
    ["d"] = { dict = "asl_d@francis", name = "asl_d_clip" },
    ["e"] = { dict = "asl_e@francis", name = "asl_e_clip" },
    ["f"] = { dict = "asl_f@francis", name = "asl_f_clip" },
    ["g"] = { dict = "asl_g@francis", name = "asl_g_clip" },
    ["h"] = { dict = "asl_h@francis", name = "asl_h_clip" },
    ["i"] = { dict = "asl_i@francis", name = "asl_i_clip" },
    ["j"] = { dict = "asl_j@francis", name = "asl_j_clip" },
    ["k"] = { dict = "asl_k@francis", name = "asl_k_clip" },
    ["l"] = { dict = "asl_l@francis", name = "asl_l_clip" },
    ["m"] = { dict = "asl_m@francis", name = "asl_m_clip" },
    ["n"] = { dict = "asl_n@francis", name = "asl_n_clip" },
    ["o"] = { dict = "asl_o@francis", name = "asl_o_clip" },
    ["p"] = { dict = "asl_p@francis", name = "asl_p_clip" },
    ["q"] = { dict = "asl_q@francis", name = "asl_q_clip" },
    ["r"] = { dict = "asl_r@francis", name = "asl_r_clip" },
    ["s"] = { dict = "asl_s@francis", name = "asl_s_clip" },
    ["t"] = { dict = "asl_t@francis", name = "asl_t_clip" },
    ["u"] = { dict = "asl_u@francis", name = "asl_u_clip" },
    ["v"] = { dict = "asl_v@francis", name = "asl_v_clip" },
    ["w"] = { dict = "asl_w@francis", name = "asl_w_clip" },
    ["x"] = { dict = "asl_x@francis", name = "asl_x_clip" },
    ["y"] = { dict = "asl_y@francis", name = "asl_y_clip" },
    ["z"] = { dict = "asl_z@francis", name = "asl_z_clip" }
}

-- Number animations with standard and alternate versions
Config.NumberAnimations = {
    ["0"] = { dict = "asl_0@francis", name = "asl_0_clip" },
    ["1"] = { dict = "asl_1@francis", name = "asl_1_clip" },
    ["2"] = { dict = "asl_2@francis", name = "asl_2_clip" },
    ["3"] = { dict = "asl_3@francis", name = "asl_3_clip" },
    ["4"] = { dict = "asl_4@francis", name = "asl_4_clip" },
    ["5"] = { dict = "asl_5@francis", name = "asl_5_clip" },
    ["6"] = { dict = "asl_6@francis", name = "asl_6_clip" },
    ["7"] = { dict = "asl_7@francis", name = "asl_7_clip" },
    ["8"] = { dict = "asl_8@francis", name = "asl_8_clip" },
    ["9"] = { dict = "asl_9@francis", name = "asl_9_clip" },
    ["1b"] = { dict = "asl_1b@francis", name = "asl_1b_clip" }, -- Alternate version
    ["2b"] = { dict = "asl_2b@francis", name = "asl_2b_clip" }, -- Alternate version
    ["3b"] = { dict = "asl_3b@francis", name = "asl_3b_clip" }, -- Alternate version
    ["4b"] = { dict = "asl_4b@francis", name = "asl_4b_clip" }, -- Alternate version
    ["5b"] = { dict = "asl_5b@francis", name = "asl_5b_clip" }, -- Alternate version
}

-- Full word/phrase animations
Config.PhraseAnimations = {
    -- Signs folder
    ["yes"] = { dict = "ebrwny_sign", name = "ebrwny_yes", duration = 1030 },
    ["no"] = { dict = "ebrwny_sign", name = "ebrwny_no", duration = 2080 },
    ["i'm good"] = { dict = "ebrwny_sign", name = "ebrwny_imgood", duration = 3940 },
    ["im good"] = { dict = "ebrwny_sign", name = "ebrwny_imgood", duration = 3940 },
    ["i am good"] = { dict = "ebrwny_sign", name = "ebrwny_imgood", duration = 3940 },
    ["see ya"] = { dict = "ebrwny_sign", name = "ebrwny_seeya", duration = 1200 },
    ["see you"] = { dict = "ebrwny_sign", name = "ebrwny_seeya", duration = 1200 },
    ["what"] = { dict = "ebrwny_sign", name = "ebrwny_what", duration = 1480 },
    
    -- Sentences folder
    ["again"] = { dict = "again@francis", name = "again_clip" },
    ["i love you"] = { dict = "i_love_you@francis", name = "i_love_you_clip" },
    ["i love you too"] = { dict = "i_love_you_2@francis", name = "i_love_you_2_clip" },
    ["my name is"] = { dict = "my_name_is@francis", name = "my_name_is_clip" },
    ["my name is prince"] = { dict = "my_name_is_prince@francis", name = "my_name_is_prince_clip" },
    ["no way"] = { dict = "no_way@francis", name = "no_way_clip" },
    ["what's up"] = { dict = "whats_up@francis", name = "whats_up_clip" },
    ["whats up"] = { dict = "whats_up@francis", name = "whats_up_clip" }, 
}

-- Special character animations (punctuation, etc.)
Config.SpecialAnimations = {
    [" "] = nil, -- no animation, just pause
    ["."] = nil, -- no animation, just pause
    ["?"] = nil, -- no animation, just pause
    ["!"] = nil, -- no animation, just pause
    [","] = nil, -- no animation, just pause
}

-- Animation settings
Config.Settings = {
    -- Animation timing
    letterDuration = 800,          -- Duration for each letter animation in ms
    wordDuration = 2000,           -- Duration for word animations in ms (default if not specified)
    pauseBetweenLetters = 200,     -- Pause between letters when spelling
    pauseBetweenWords = 500,       -- Pause between words
    
    -- Animation flags
    animFlag = 49,                 -- Upper body only + Allow movement + Loop
    blendInSpeed = 8.0,
    blendOutSpeed = -8.0,
    
    -- Camera settings
    cameraTransitionTime = 1500,   -- Smooth camera transition time in ms
    cameraFOV = 65.0,              -- Field of view for ASL camera
    maxTargetDistance = 10.0,      -- Maximum distance to find target player
    
    -- UI settings
    showSubtitles = true,          -- Show what's being signed
    showInstructions = true,       -- Show control instructions
    
    -- Control settings
    stopKey = 73,                  -- X key to stop/cancel
    allowMovement = false,         -- Allow player to move while signing
    
    -- Debug settings
    debugMode = false,             -- Show debug information
    testMode = false               -- Don't require nearby players for testing
}

-- Text normalization rules
Config.TextRules = {
    -- Common abbreviations to expand
    abbreviations = {
        ["ur"] = "your",
        ["u"] = "you",
        ["r"] = "are",
        ["y"] = "why",
        ["thx"] = "thanks",
        ["ty"] = "thank you",
        ["pls"] = "please",
        ["plz"] = "please",
        ["idk"] = "i don't know",
        ["idc"] = "i don't care",
        ["omw"] = "on my way",
        ["brb"] = "be right back",
        ["gtg"] = "got to go",
        ["ily"] = "i love you",
        ["ily2"] = "i love you too",
        ["sup"] = "what's up",
        ["wassup"] = "what's up",
        ["cya"] = "see ya",
        ["im"] = "i'm",
        ["dont"] = "don't",
        ["wont"] = "won't",
        ["cant"] = "can't",
        ["shouldnt"] = "shouldn't",
        ["wouldnt"] = "wouldn't"
    }
}