import SwiftUI

struct TomOliverParticle: Identifiable {
  let id = UUID()
  var x: CGFloat
  var y: CGFloat
  var rotation: Double
  var scale: CGFloat
  var opacity: Double
  var speed: CGFloat
  var rotationSpeed: Double
  var horizontalDrift: CGFloat
}

@MainActor
struct TomOliverParticleView: View {

  @State private var particles: [TomOliverParticle] = []
  @State private var emitTask: Task<Void, Never>?

  private let maxParticles = 30

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(particles) { particle in
          Image("tom_oliver_particle", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50 * particle.scale, height: 80 * particle.scale)
            .rotationEffect(.degrees(particle.rotation))
            .opacity(particle.opacity)
            .position(x: particle.x, y: particle.y)
        }
      }
      .allowsHitTesting(false)
      .task {
        await startEmitting(in: geometry.size)
      }
    }
    .allowsHitTesting(false)
    .onDisappear {
      emitTask?.cancel()
    }
  }

  private func startEmitting(in size: CGSize) async {
    // Initial burst
    for _ in 0..<15 {
      guard !Task.isCancelled else { return }
      spawnParticle(in: size)
      try? await Task.sleep(for: .milliseconds(80))
    }

    // Continue emitting
    while !Task.isCancelled {
      try? await Task.sleep(for: .milliseconds(400))
      guard !Task.isCancelled else { return }
      if particles.count < maxParticles {
        spawnParticle(in: size)
      }
    }
  }

  private func spawnParticle(in size: CGSize) {
    let particle = TomOliverParticle(
      x: CGFloat.random(in: 0...size.width),
      y: -100,
      rotation: Double.random(in: -30...30),
      scale: CGFloat.random(in: 0.4...1.0),
      opacity: Double.random(in: 0.7...1.0),
      speed: CGFloat.random(in: 1.5...3.5),
      rotationSpeed: Double.random(in: -2...2),
      horizontalDrift: CGFloat.random(in: -0.5...0.5)
    )
    particles.append(particle)

    let duration = Double(size.height + 200) / Double(particle.speed * 60)
    let particleId = particle.id

    withAnimation(.linear(duration: duration)) {
      if let index = particles.firstIndex(where: { $0.id == particleId }) {
        particles[index].y = size.height + 100
        particles[index].rotation += particle.rotationSpeed * duration * 30
        particles[index].x += particle.horizontalDrift * size.width * 0.3
      }
    }

    Task {
      try? await Task.sleep(for: .seconds(duration))
      particles.removeAll { $0.id == particleId }
    }
  }
}
