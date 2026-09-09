CreateThread(function()
    if not Config.CheckUpdates then return end

    Wait(1000)

    PerformHttpRequest('https://api.github.com/repos/' .. Config.GithubRepo .. '/releases/latest', function(errorCode, resultData, resultHeaders)
        if errorCode ~= 200 then
            print('^3[kt-vehicle-registration]^0 Nije moguce proveriti verziju (GitHub API kod: ' .. tostring(errorCode) .. ')')
            return
        end

        local ok, data = pcall(json.decode, resultData)
        if not ok or not data or not data.tag_name then
            print('^3[kt-vehicle-registration]^0 Neuspesno citanje GitHub odgovora.')
            return
        end

        local latest = data.tag_name:gsub('^v', '')
        local current = Config.Version

        if latest == current then
            print('^2[kt-vehicle-registration]^0 Koristis najnoviju verziju (' .. current .. ')')
        else
            print('^1========================================^0')
            print('^1[kt-vehicle-registration] NOVA VERZIJA DOSTUPNA!^0')
            print('^1Trenutna verzija: ' .. current .. '^0')
            print('^2Najnovija verzija: ' .. latest .. '^0')
            print('^1Preuzmi je ovde: https://github.com/' .. Config.GithubRepo .. '/releases/latest^0')
            print('^1========================================^0')
        end
    end, 'GET', '', { ['User-Agent'] = 'kt-vehicle-registration-versioncheck' })
end)