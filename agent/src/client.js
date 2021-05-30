"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
exports.buildClient = void 0;
var admin = require("firebase-admin");
var tmi = require("tmi.js");
var uuid_1 = require("uuid");
function buildClient() {
    var _this = this;
    var id = uuid_1.v4();
    var client = new tmi.Client({
        connection: { reconnect: true },
        channels: []
    });
    client.connect();
    client.on("message", function (channel, tags, message) { return __awaiter(_this, void 0, void 0, function () {
        var timestamp;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    timestamp = admin.firestore.Timestamp.fromMillis(Number(tags["tmi-sent-ts"]));
                    return [4 /*yield*/, admin
                            .firestore()
                            .collection("messages")
                            .doc("twitch:" + tags.id)
                            .set({
                            channel: channel,
                            channelId: "twitch:" + tags["room-id"],
                            type: "message",
                            timestamp: timestamp,
                            tags: tags,
                            message: message
                        })];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    }); });
    client.on("messagedeleted", function (channel, username, deletedMessage, tags) { return __awaiter(_this, void 0, void 0, function () {
        var timestamp;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    timestamp = admin.firestore.Timestamp.fromMillis(Number(tags["tmi-sent-ts"]));
                    return [4 /*yield*/, admin
                            .firestore()
                            .collection("messages")
                            .doc("twitch:" + tags.id)
                            .set({
                            channel: channel,
                            channelId: "twitch:" + tags["room-id"],
                            type: "messagedeleted",
                            timestamp: timestamp,
                            tags: tags,
                            messageId: tags["target-msg-id"]
                        })];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    }); });
    client.on("raided", (function (channel, username, viewers, tags) { return __awaiter(_this, void 0, void 0, function () {
        var timestamp;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    timestamp = admin.firestore.Timestamp.fromMillis(Number(tags["tmi-sent-ts"]));
                    return [4 /*yield*/, admin
                            .firestore()
                            .collection("messages")
                            .doc("twitch:" + tags.id)
                            .set({
                            channel: channel,
                            channelId: "twitch:" + tags["room-id"],
                            type: "raided",
                            timestamp: timestamp,
                            tags: tags,
                            username: username,
                            viewers: viewers
                        })];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    }); }));
    client.on("connected", function () { return console.log("client " + id + " connected"); });
    client.on("connecting", function () { return console.log("client " + id + " connecting"); });
    client.on("disconnected", function () { return console.log("client " + id + " disconnected"); });
    client.on("reconnect", function () { return console.log("client " + id + " reconnecting"); });
    return client;
}
exports.buildClient = buildClient;
