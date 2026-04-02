// Buddy/Engine/MovementProfile.swift
import Foundation

/// 캐릭터별 움직임 특성을 정의하는 프로파일
struct MovementProfile {
    // 속도
    let minSpeed: CGFloat
    let maxSpeed: CGFloat

    // 방향 전환 주기 (초)
    let minDirectionInterval: CGFloat
    let maxDirectionInterval: CGFloat

    // 보빙 (둥실둥실/통통)
    let bobAmplitudeY: CGFloat    // 수직 진폭
    let bobAmplitudeX: CGFloat    // 수평 진폭
    let bobFrequencyY: CGFloat    // 수직 주파수
    let bobFrequencyX: CGFloat    // 수평 주파수

    // 멈추기
    let pauseProbability: CGFloat // 0~1
    let minPauseDuration: CGFloat
    let maxPauseDuration: CGFloat

    // 속도 보간 (높을수록 속도 변화가 빠름)
    let speedLerpRate: CGFloat

    // 경계 반사 시 방향 흔들림
    let bounceNudge: CGFloat

    // 가속 (갑작스러운 속도 변화)
    let dashProbability: CGFloat  // 방향 전환 시 대시할 확률
    let dashSpeedMultiplier: CGFloat
}

extension MovementProfile {

    /// 👻 유령 — 둥실둥실 떠다니는 유령다운 움직임
    static let ghost = MovementProfile(
        minSpeed: 8, maxSpeed: 25,
        minDirectionInterval: 4, maxDirectionInterval: 10,
        bobAmplitudeY: 6, bobAmplitudeX: 3,
        bobFrequencyY: 1.2, bobFrequencyX: 0.7,
        pauseProbability: 0.2,
        minPauseDuration: 1.5, maxPauseDuration: 4,
        speedLerpRate: 0.02,
        bounceNudge: 0.4,
        dashProbability: 0, dashSpeedMultiplier: 1
    )

    /// 🐱 고양이 — 빠르고 민첩, 갑자기 돌진하고 자주 멈춰서 관찰
    static let cat = MovementProfile(
        minSpeed: 15, maxSpeed: 40,
        minDirectionInterval: 2, maxDirectionInterval: 5,
        bobAmplitudeY: 1.5, bobAmplitudeX: 0.5,
        bobFrequencyY: 3.0, bobFrequencyX: 1.5,
        pauseProbability: 0.3,
        minPauseDuration: 1, maxPauseDuration: 3,
        speedLerpRate: 0.08,
        bounceNudge: 0.6,
        dashProbability: 0.25, dashSpeedMultiplier: 2.5
    )

    /// 🟢 슬라임 — 느리고 통통 튀는 느낌
    static let slime = MovementProfile(
        minSpeed: 5, maxSpeed: 15,
        minDirectionInterval: 5, maxDirectionInterval: 12,
        bobAmplitudeY: 10, bobAmplitudeX: 1,
        bobFrequencyY: 2.5, bobFrequencyX: 0.5,
        pauseProbability: 0.15,
        minPauseDuration: 0.8, maxPauseDuration: 2,
        speedLerpRate: 0.03,
        bounceNudge: 0.3,
        dashProbability: 0, dashSpeedMultiplier: 1
    )

    /// ☁️ 구름 — 매우 느리고 부드럽게 흘러가는 바람 같은 움직임
    static let cloud = MovementProfile(
        minSpeed: 3, maxSpeed: 10,
        minDirectionInterval: 8, maxDirectionInterval: 15,
        bobAmplitudeY: 3, bobAmplitudeX: 5,
        bobFrequencyY: 0.6, bobFrequencyX: 0.4,
        pauseProbability: 0.08,
        minPauseDuration: 2, maxPauseDuration: 6,
        speedLerpRate: 0.01,
        bounceNudge: 0.2,
        dashProbability: 0, dashSpeedMultiplier: 1
    )

    /// 이미지 캐릭터용 기본값 (유령과 동일)
    static let `default` = ghost
}

extension CharacterAppearance {
    var movementProfile: MovementProfile {
        switch self {
        case .ghost: return .ghost
        case .cat: return .cat
        case .slime: return .slime
        case .cloud: return .cloud
        case .image: return .default
        }
    }
}
