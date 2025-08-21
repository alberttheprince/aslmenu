Config = {}

-- Animation dictionary mapping based on GitHub structure
-- Pattern: asl_[letter/word]@francis
Config.AnimationDict = "asl@francis" -- Base dictionary name

-- Letter animations (based on naming convention from GitHub)
Config.LetterAnimations = {
    ["a"] = "asl_a@francis",
    ["b"] = "asl_b@francis",
    ["c"] = "asl_c@francis",
    ["d"] = "asl_d@francis",
    ["e"] = "asl_e@francis",
    ["f"] = "asl_f@francis",
    ["g"] = "asl_g@francis",
    ["h"] = "asl_h@francis",
    ["i"] = "asl_i@francis",
    ["j"] = "asl_j@francis",
    ["k"] = "asl_k@francis",
    ["l"] = "asl_l@francis",
    ["m"] = "asl_m@francis",
    ["n"] = "asl_n@francis",
    ["o"] = "asl_o@francis",
    ["p"] = "asl_p@francis",
    ["q"] = "asl_q@francis",
    ["r"] = "asl_r@francis",
    ["s"] = "asl_s@francis",
    ["t"] = "asl_t@francis",
    ["u"] = "asl_u@francis",
    ["v"] = "asl_v@francis",
    ["w"] = "asl_w@francis",
    ["x"] = "asl_x@francis",
    ["y"] = "asl_y@francis",
    ["z"] = "asl_z@francis"
}

-- Number animations (if available)
Config.NumberAnimations = {
    ["0"] = "asl_0@francis",
    ["1"] = "asl_1@francis",
    ["2"] = "asl_2@francis",
    ["3"] = "asl_3@francis",
    ["4"] = "asl_4@francis",
    ["5"] = "asl_5@francis",
    ["6"] = "asl_6@francis",
    ["7"] = "asl_7@francis",
    ["8"] = "asl_8@francis",
    ["9"] = "asl_9@francis"
}

-- Full word/phrase animations
Config.PhraseAnimations = {
    ["hello"] = "asl_hello@francis",
    ["hello my name is"] = "asl_hello_my_name_is@francis",
    ["thank you"] = "asl_thank_you@francis",
    ["please"] = "asl_please@francis",
    ["sorry"] = "asl_sorry@francis",
    ["yes"] = "asl_yes@francis",
    ["no"] = "asl_no@francis",
    ["goodbye"] = "asl_goodbye@francis",
    ["help"] = "asl_help@francis",
    ["i love you"] = "asl_i_love_you@francis",
    ["what"] = "asl_what@francis",
    ["where"] = "asl_where@francis",
    ["when"] = "asl_when@francis",
    ["why"] = "asl_why@francis",
    ["how"] = "asl_how@francis"
}

-- Animation settings
Config.Settings = {
    -- Animation timing
    letterDuration = 800,      -- Duration for each letter animation in ms
    wordDuration = 2000,       -- Duration for word animations in ms
    pauseBetweenLetters = 200, -- Pause between letters when spelling
    pauseBetweenWords = 500,   -- Pause between words
    
    -- Animation flags
    animFlag = 49,             -- Upper body only + Allow movement + Loop
    blendInSpeed = 8.0,
    blendOutSpeed = -8.0,
    
    -- Camera settings
    cameraTransitionTime = 1500,  -- Smooth camera transition time in ms
    cameraFOV = 65.0,             -- Field of view for ASL camera
    maxTargetDistance = 10.0,     -- Maximum distance to find target player
    
    -- UI settings
    showSubtitles = true,      -- Show what's being signed
    showInstructions = true,   -- Show control instructions
    
    -- Control settings
    stopKey = 73,              -- X key to stop/cancel
    allowMovement = false,     -- Allow player to move while signing
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
        ["gtg"] = "got to go"
    }
}
