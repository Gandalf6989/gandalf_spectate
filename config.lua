Config = {}

-- Engedélyezett adminok.
Config.AllowAdmins = {"owner", "developer", "superadmin", "admin", "mod"}

-- job, monkey, bank, black_money frissítés.
Config.UpdateTime = 10 -- 10 perc, optimalizáció szempontjából jobb ha ezen az értéken marad.

-- Spectate menü megnyitási paraméterek.
Config.OpenSpectate = {
    Command = "spec", -- Command amivel megnyitható a menü.

    Button = 9, -- Gomb amivel megnyitható a menü.

    Name = "Admin spectate" -- Név amit kiír a KeyBinds menüpontban.
}

