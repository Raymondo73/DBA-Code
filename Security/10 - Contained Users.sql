/*
    Red flags: Many contained users you didn’t expect; UNSAFE/EXTERNAL_ACCESS assemblies.

    - Contained users (authentication_type_desc = DATABASE or NONE) mean credentials are stored inside the database 
    (not mapped to server logins). This is expected for contained DB scenarios, but be cautious:

        - Confirm which applications require contained users.
        - Check password policies & lifecycle for those accounts.
        - Make sure contained DBs have appropriate access controls and monitoring.

    - Assemblies with EXTERNAL_ACCESS or UNSAFE can execute code outside SQL Server or run unmanaged code:

        - UNSAFE is the highest risk — treat any unexpected UNSAFE assembly as a red flag
        - EXTERNAL_ACCESS allows file/OS/network interactions and should be audited and justified.
        - Verify the owner of the DB (not sa), review the assembly origin/signature, and consider 
        requiring AUTHORIZATION or certificate signing.

*/
