int g_iBeamSprite = 0;
int g_iHaloSprite = 0;
Bombsite g_ShowingSite = BombsiteA;
bool g_ShowingBombSpawns = false;

public void MovePlayerToEditMode(int client) {
    SwitchPlayerTeam(client, CS_TEAM_CT);
    CS_RespawnPlayer(client);
}

public Action Timer_ShowSpawns(Handle timer) {
    if (!g_ShowingSpawns || g_hEditorEnabled.IntValue == 0)
        return Plugin_Continue;

    g_iBeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
    g_iHaloSprite = PrecacheModel("sprites/halo.vmt", true);
    float origin[3];
    float angle[3];

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsValidClient(i) || IsFakeClient(i))
            continue;

        for (int j = 0; j < g_NumSpawns; j++) {
            origin = g_SpawnPoints[j];
            angle = g_SpawnPoints[j];
            if (SpawnFilter(j))
                DisplaySpawnPoint(i, origin, angle, 40.0, g_SpawnTeams[j] == CS_TEAM_CT);
        }
    }

    return Plugin_Continue;
}

stock bool SpawnFilter(int spawn, int teamFilter=-1) {
    bool showing = !g_SpawnDeleted[spawn] &&
                    g_ShowingSite == g_SpawnSites[spawn] &&
                    (!g_ShowingBombSpawns || CanBombCarrierSpawn(spawn));

    if (teamFilter == -1)
        return showing;
    else
        return showing && g_SpawnTeams[spawn] == teamFilter;
}

public void FinishSpawn() {
    g_SpawnDeleted[g_NumSpawns] = false;
    g_SpawnOnlyBomb[g_NumSpawns] = false;
    g_SpawnNoBomb[g_NumSpawns] = false;
    g_NumSpawns++;
    Retakes_MessageToAll("Finished adding %s spawn for %s.",
                         TEAMSTRING(g_SpawnTeams[g_NumSpawns]),
                         SITESTRING(g_SpawnSites[g_NumSpawns]));

    if (g_NumSpawns == MAX_SPAWNS) {
        Retakes_MessageToAll("{DARK_RED}WARNING: {NORMAL}the maximum number of spawns has been reached. {LIGHT_RED}New spawns will override old ones.");
        LogError("Maximum number of spawns reached");
    }
}

public void DisplaySpawnPoint(int client, const float position[3], const float angles[3], float size, bool ct) {
    float direction[3];

    GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(direction, size/2);
    AddVectors(position, direction, direction);

    int r, g, b, a;
    if (ct) {
        r = 0;
        g = 0;
        b = 255;
        a = 255;
    } else {
        r = 255;
        g = 0;
        b = 0;
        a = 255;
    }

    TE_Start("BeamRingPoint");
    TE_WriteVector("m_vecCenter", position);
    TE_WriteFloat("m_flStartRadius", 10.0);
    TE_WriteFloat("m_flEndRadius", size);
    TE_WriteNum("m_nModelIndex", g_iBeamSprite);
    TE_WriteNum("m_nHaloIndex", g_iHaloSprite);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", 0);
    TE_WriteFloat("m_fLife", 1.0);
    TE_WriteFloat("m_fWidth", 1.0);
    TE_WriteFloat("m_fEndWidth", 1.0);
    TE_WriteFloat("m_fAmplitude", 0.0);
    TE_WriteNum("r", r);
    TE_WriteNum("g", g);
    TE_WriteNum("b", b);
    TE_WriteNum("a", a);
    TE_WriteNum("m_nSpeed", 50);
    TE_WriteNum("m_nFlags", 0);
    TE_WriteNum("m_nFadeLength", 0);
    TE_SendToClient(client);

    TE_Start("BeamPoints");
    TE_WriteVector("m_vecStartPoint", position);
    TE_WriteVector("m_vecEndPoint", direction);
    TE_WriteNum("m_nModelIndex", g_iBeamSprite);
    TE_WriteNum("m_nHaloIndex", g_iHaloSprite);
    TE_WriteNum("m_nStartFrame", 0);
    TE_WriteNum("m_nFrameRate", 0);
    TE_WriteFloat("m_fLife", 1.0);
    TE_WriteFloat("m_fWidth", 1.0);
    TE_WriteFloat("m_fEndWidth", 1.0);
    TE_WriteFloat("m_fAmplitude", 0.0);
    TE_WriteNum("r", r);
    TE_WriteNum("g", g);
    TE_WriteNum("b", b);
    TE_WriteNum("a", a);
    TE_WriteNum("m_nSpeed", 50);
    TE_WriteNum("m_nFlags", 0);
    TE_WriteNum("m_nFadeLength", 0);
    TE_SendToClient(client);
}

stock int FindClosestSpawn(int client, int teamFilter=-1) {
    int closest = -1;
    float minDist = 0.0;
    for (int i = 0; i < g_NumSpawns; i++) {
        if (!SpawnFilter(i, teamFilter))
            continue;

        float origin[3];
        origin = g_SpawnPoints[i];

        float playerOrigin[3];
        GetClientAbsOrigin(client, playerOrigin);

        float dist = GetVectorDistance(origin, playerOrigin);
        if (closest < 0 || dist < minDist) {
            minDist = dist;
            closest = i;
        }
    }
    return closest;
}

public void DeleteClosestSpawn(int client) {
    int closest = FindClosestSpawn(client);
    if (closest >= 0) {
        Retakes_MessageToAll("Deleted spawn %d", closest);
        g_SpawnDeleted[closest] = true;
    }
}

public void SaveSpawns() {
    WriteSpawns();
    Retakes_MessageToAll("Map spawns saved.");
}

public void ReloadSpawns() {
    g_NumSpawns = ParseSpawns();
    Retakes_MessageToAll("Imported %d map spawns.", g_NumSpawns);
}
