#include scripts\amrv\_command_lib;
#include maps\mp\zombies\_zm_utility;

init() {
    // Adjusting dvars
    if (!isDefined(GetDvar("admin_password")))
        SetDvar("admin_password","admin");

    if (!isDefined(GetDvar("admin_users"))) {
        SetDvar("admin_users", " ");
    }

    // Declaring the commands
    setCommand("password",::command_password);
    setCommand("god",::command_god,::checkPermission);
    setCommand("ammo",::command_ammo,::checkPermission);
    setCommand("score",::command_score,::checkPermission);
    setCommand("weapon",::command_weapon,::checkPermission);
    // This command needs to be executed on a separate thread
    setThreadedCommand("sudo",::command_sudo,::checkPermission);
}

command_weapon(player, args) {
    weapon = args[0];

    if (!isDefined(weapon)) {
        player iPrintLn("Invalid argument, write the ^3internal^7 name of the weapon");
        return;
    }

    if (weaponClass(weapon) == "none") {
        player iPrintLn("Unknown weapon '^1" + weapon + "^7'");
        return;
    }
    if (player getWeaponsListPrimaries().size >= get_player_weapon_limit(player))
        player takeWeapon(player getCurrentWeapon());
        
    player giveWeapon(weapon);
    player switchToWeapon(weapon);
    player giveMaxAmmo(weapon);
    player iPrintLn("Gave " + weaponClass(weapon) + " '^2" + weapon + "^7'");
}

// This commands allows the user to execute commands as if it was other player
command_sudo(player, args) {
    // Check that the command is not executed without the receiver and the command to execute
    if (args.size < 2) {
        player iPrintLn("Invalid parameters, use /sudo <player> <command...>");
        return;
    }

    // Obtain the receiver player
    receiver = "";
    foreach (user in level.players) {
        if (user.name == args[0]) {
            receiver = user;
            break;
        }
    }

    // If no player was found then no action is done
    if (!isDefined(receiver)) {
        player iPrintLn("Unknown player " + args[0]);
        return;
    }

    // Convert the array of arguments into a new formatted message
    for (i = 1; i < args.size; i++)
        message += args[i] + " ";

    level notify("say", message, receiver, true);
    player iPrintLn("Suded command " + args[1] + " as player " + receiver.name);
}

// This command gives max ammo to the player for every of his weapons
// Is declared to need special permission
command_ammo(player, args) {
    foreach (weapon in player GetWeaponsList()) {
        player SetWeaponAmmoClip(weapon, weaponClipSize(weapon));
        player GiveMaxAmmo(weapon);
    }
}

// This command gives or retrieves points from the player
// Is declared to need special permission
command_score(player, args) {
    score = int(args[0]);

    if (IsInt(score)) {
        player.score += score;
    } else {
        player iPrintLn("Pleasle input the amount");
    }
}

command_god(player, args) {
    if (!isDefined(args[0])) {
        player iPrintLn("Invalid parameter, type enable/disable");
        return;
    }

    switch (toLower(args[0])) {
        case "enable":
            player enableInvulnerability();
            player iPrintLnBold("God mode ^2enabled");
        break;
        case "disable":
            player disableInvulnerability();
            player iPrintLnBold("God mode ^1disabled");
            break;
        default:
            player iPrintLn("^1Invalid parameter ^7" + args[0]);
            break;
    }

}

command_password(player, args) {
    password = args[0];

    if (!isDefined(password)) {
        player iPrintLn("^1No password provided");
        return;
    }

    if (args[0] == GetDvar("admin_password")) {
        player iPrintLn("^2You are now OP");
        SetDvar("admin_users", GetDvar("admin_users")+player.guid+" ");
        player.isOp = true;
    } else {
        player iPrintLn("^1Invalid password");
    }
}

checkPermission(player) {
    return player.isOp == true || isSubStr(GetDvar("admin_users"),player.guid);
}