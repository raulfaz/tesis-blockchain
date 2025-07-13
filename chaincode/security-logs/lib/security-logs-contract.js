// SecurityLogs Chaincode - Para sistema de logs de seguridad
// Desarrollado para tesis blockchain

'use strict';

const { Contract } = require('fabric-contract-api');

class SecurityLogsContract extends Contract {

    // Inicializar el ledger
    async initLedger(ctx) {
        console.info('============= START : Initialize Ledger ===========');
        
        const sampleLogs = [
            {
                logId: 'LOG001',
                timestamp: '2025-07-13T10:00:00Z',
                logType: 'AUTHENTICATION',
                severity: 'INFO',
                userId: 'user123',
                sourceIP: '192.168.1.100',
                action: 'LOGIN_SUCCESS',
                resource: '/dashboard',
                message: 'Usuario autenticado correctamente',
                metadata: {
                    userAgent: 'Mozilla/5.0',
                    sessionId: 'sess_123',
                    location: 'Ecuador'
                },
                status: 'ACTIVE',
                createdBy: 'system',
                auditTrail: []
            },
            {
                logId: 'LOG002',
                timestamp: '2025-07-13T10:05:00Z',
                logType: 'ACCESS_CONTROL',
                severity: 'WARNING',
                userId: 'user456',
                sourceIP: '192.168.1.101',
                action: 'ACCESS_DENIED',
                resource: '/admin/users',
                message: 'Intento de acceso denegado a área administrativa',
                metadata: {
                    userAgent: 'Mozilla/5.0',
                    attemptCount: 3,
                    reason: 'INSUFFICIENT_PRIVILEGES'
                },
                status: 'ACTIVE',
                createdBy: 'security_module',
                auditTrail: []
            }
        ];

        for (let i = 0; i < sampleLogs.length; i++) {
            sampleLogs[i].docType = 'securityLog';
            await ctx.stub.putState(sampleLogs[i].logId, Buffer.from(JSON.stringify(sampleLogs[i])));
            console.info('Added <--> ', sampleLogs[i]);
        }

        console.info('============= END : Initialize Ledger ===========');
    }

    // Crear nuevo log de seguridad
    async createSecurityLog(ctx, logId, timestamp, logType, severity, userId, sourceIP, action, resource, message, metadata) {
        console.info('============= START : Create Security Log ===========');

        // Validar que el log no exista
        const exists = await this.securityLogExists(ctx, logId);
        if (exists) {
            throw new Error(`El log ${logId} ya existe`);
        }

        // Validar campos requeridos
        if (!logId || !timestamp || !logType || !severity || !action) {
            throw new Error('Los campos logId, timestamp, logType, severity y action son obligatorios');
        }

        // Obtener información del invocador
        const clientIdentity = ctx.clientIdentity;
        const mspId = clientIdentity.getMSPID();
        const createdBy = `${mspId}:${clientIdentity.getID()}`;

        // Crear el log
        const securityLog = {
            docType: 'securityLog',
            logId: logId,
            timestamp: timestamp,
            logType: logType,
            severity: severity,
            userId: userId || 'anonymous',
            sourceIP: sourceIP || 'unknown',
            action: action,
            resource: resource || '',
            message: message || '',
            metadata: metadata ? JSON.parse(metadata) : {},
            status: 'ACTIVE',
            createdBy: createdBy,
            createdAt: new Date().toISOString(),
            auditTrail: [
                {
                    action: 'CREATED',
                    timestamp: new Date().toISOString(),
                    by: createdBy,
                    details: 'Log de seguridad creado'
                }
            ]
        };

        // Guardar en el ledger
        await ctx.stub.putState(logId, Buffer.from(JSON.stringify(securityLog)));

        // Emitir evento
        await ctx.stub.setEvent('SecurityLogCreated', Buffer.from(JSON.stringify({
            logId: logId,
            logType: logType,
            severity: severity,
            timestamp: timestamp
        })));

        console.info('============= END : Create Security Log ===========');
        return JSON.stringify(securityLog);
    }

    // Consultar log por ID
    async querySecurityLog(ctx, logId) {
        const logAsBytes = await ctx.stub.getState(logId);
        if (!logAsBytes || logAsBytes.length === 0) {
            throw new Error(`El log ${logId} no existe`);
        }
        return logAsBytes.toString();
    }

    // Verificar si un log existe
    async securityLogExists(ctx, logId) {
        const logAsBytes = await ctx.stub.getState(logId);
        return logAsBytes && logAsBytes.length > 0;
    }

    // Consultar todos los logs de seguridad
    async queryAllSecurityLogs(ctx) {
        const startKey = '';
        const endKey = '';
        const allResults = [];
        
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            
            if (record.docType === 'securityLog') {
                allResults.push({Key: key, Record: record});
            }
        }
        
        return JSON.stringify(allResults);
    }

    // Consultar logs por tipo
    async queryLogsByType(ctx, logType) {
        let queryString = {
            "selector": {
                "docType": "securityLog",
                "logType": logType
            }
        };

        let queryResults = await this.getQueryResultForQueryString(ctx, JSON.stringify(queryString));
        return queryResults;
    }

    // Consultar logs por severidad
    async queryLogsBySeverity(ctx, severity) {
        let queryString = {
            "selector": {
                "docType": "securityLog",
                "severity": severity
            }
        };

        let queryResults = await this.getQueryResultForQueryString(ctx, JSON.stringify(queryString));
        return queryResults;
    }

    // Consultar logs por usuario
    async queryLogsByUser(ctx, userId) {
        let queryString = {
            "selector": {
                "docType": "securityLog",
                "userId": userId
            }
        };

        let queryResults = await this.getQueryResultForQueryString(ctx, JSON.stringify(queryString));
        return queryResults;
    }

    // Actualizar estado del log (para auditores)
    async updateLogStatus(ctx, logId, newStatus, reason) {
        console.info('============= START : Update Log Status ===========');

        const logAsBytes = await ctx.stub.getState(logId);
        if (!logAsBytes || logAsBytes.length === 0) {
            throw new Error(`El log ${logId} no existe`);
        }

        const securityLog = JSON.parse(logAsBytes.toString());
        
        // Verificar permisos (solo LogAuditor puede actualizar)
        const clientIdentity = ctx.clientIdentity;
        const mspId = clientIdentity.getMSPID();
        if (mspId !== 'LogAuditorMSP') {
            throw new Error('Solo los auditores pueden actualizar el estado de los logs');
        }

        const updatedBy = `${mspId}:${clientIdentity.getID()}`;
        const oldStatus = securityLog.status;

        // Actualizar estado
        securityLog.status = newStatus;
        securityLog.updatedAt = new Date().toISOString();
        securityLog.updatedBy = updatedBy;

        // Agregar entrada al audit trail
        securityLog.auditTrail.push({
            action: 'STATUS_UPDATED',
            timestamp: new Date().toISOString(),
            by: updatedBy,
            details: `Estado cambiado de ${oldStatus} a ${newStatus}. Razón: ${reason || 'No especificada'}`
        });

        // Guardar cambios
        await ctx.stub.putState(logId, Buffer.from(JSON.stringify(securityLog)));

        // Emitir evento
        await ctx.stub.setEvent('SecurityLogStatusUpdated', Buffer.from(JSON.stringify({
            logId: logId,
            oldStatus: oldStatus,
            newStatus: newStatus,
            updatedBy: updatedBy
        })));

        console.info('============= END : Update Log Status ===========');
        return JSON.stringify(securityLog);
    }

    // Función auxiliar para consultas
    async getQueryResultForQueryString(ctx, queryString) {
        console.info('- getQueryResultForQueryString queryString:\n' + queryString);

        let resultsIterator = await ctx.stub.getQueryResult(queryString);
        let results = await this.getAllResults(resultsIterator, false);

        return JSON.stringify(results);
    }

    // Función auxiliar para procesar resultados
    async getAllResults(iterator, isHistory) {
        let allResults = [];
        let res = await iterator.next();
        
        while (!res.done) {
            if (res.value && res.value.value.toString()) {
                let jsonRes = {};
                console.log(res.value.value.toString('utf8'));
                
                if (isHistory && isHistory === true) {
                    jsonRes.TxId = res.value.txId;
                    jsonRes.Timestamp = res.value.timestamp;
                    try {
                        jsonRes.Value = JSON.parse(res.value.value.toString('utf8'));
                    } catch (err) {
                        console.log(err);
                        jsonRes.Value = res.value.value.toString('utf8');
                    }
                } else {
                    jsonRes.Key = res.value.key;
                    try {
                        jsonRes.Record = JSON.parse(res.value.value.toString('utf8'));
                    } catch (err) {
                        console.log(err);
                        jsonRes.Record = res.value.value.toString('utf8');
                    }
                }
                allResults.push(jsonRes);
            }
            res = await iterator.next();
        }
        
        iterator.close();
        return allResults;
    }
}

module.exports = SecurityLogsContract;
