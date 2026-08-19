use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BenchmarkMetric {
    pub timestamp_sec: f32,
    pub fps: f32,
    pub frametime_ms: f32,
    pub gpu_load_pct: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BenchmarkSession {
    pub session_id: String,
    pub game_id: String,
    pub chip_name: String,
    pub duration_seconds: f32,
    pub avg_fps: f32,
    pub one_percent_low_fps: f32,
    pub min_fps: f32,
    pub max_fps: f32,
    pub avg_frametime_ms: f32,
    pub samples_count: usize,
    pub metrics: Vec<BenchmarkMetric>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegressionReport {
    pub game_id: String,
    pub baseline_avg_fps: f32,
    pub candidate_avg_fps: f32,
    pub fps_delta_pct: f32,
    pub is_regression: bool,
    pub regression_threshold_pct: f32,
    pub summary: String,
}

pub struct BenchmarkEngine;

impl BenchmarkEngine {
    pub fn compute_session(
        session_id: &str,
        game_id: &str,
        chip_name: &str,
        metrics: Vec<BenchmarkMetric>,
    ) -> BenchmarkSession {
        if metrics.is_empty() {
            return BenchmarkSession {
                session_id: session_id.to_string(),
                game_id: game_id.to_string(),
                chip_name: chip_name.to_string(),
                duration_seconds: 0.0,
                avg_fps: 0.0,
                one_percent_low_fps: 0.0,
                min_fps: 0.0,
                max_fps: 0.0,
                avg_frametime_ms: 0.0,
                samples_count: 0,
                metrics: Vec::new(),
            };
        }

        let mut fps_values: Vec<f32> = metrics.iter().map(|m| m.fps).collect();
        fps_values.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));

        let sum_fps: f32 = fps_values.iter().sum();
        let avg_fps = sum_fps / fps_values.len() as f32;

        let min_fps = *fps_values.first().unwrap_or(&0.0);
        let max_fps = *fps_values.last().unwrap_or(&0.0);

        let one_pct_idx = (fps_values.len() as f32 * 0.01).floor() as usize;
        let one_percent_low = fps_values[one_pct_idx.min(fps_values.len() - 1)];

        let sum_ft: f32 = metrics.iter().map(|m| m.frametime_ms).sum();
        let avg_frametime = sum_ft / metrics.len() as f32;
        let duration = metrics.last().map(|m| m.timestamp_sec).unwrap_or(0.0);

        BenchmarkSession {
            session_id: session_id.to_string(),
            game_id: game_id.to_string(),
            chip_name: chip_name.to_string(),
            duration_seconds: duration,
            avg_fps: (avg_fps * 10.0).round() / 10.0,
            one_percent_low_fps: (one_percent_low * 10.0).round() / 10.0,
            min_fps: (min_fps * 10.0).round() / 10.0,
            max_fps: (max_fps * 10.0).round() / 10.0,
            avg_frametime_ms: (avg_frametime * 10.0).round() / 10.0,
            samples_count: metrics.len(),
            metrics,
        }
    }

    pub fn evaluate_regression(
        baseline: &BenchmarkSession,
        candidate: &BenchmarkSession,
        threshold_pct: f32,
    ) -> RegressionReport {
        let delta = if baseline.avg_fps > 0.0 {
            ((candidate.avg_fps - baseline.avg_fps) / baseline.avg_fps) * 100.0
        } else {
            0.0
        };

        let is_regression = delta < -threshold_pct;
        let summary = if is_regression {
            format!(
                "Performance REGRESSION detected: {:.1}% drop in average FPS (Baseline: {:.1} FPS vs Candidate: {:.1} FPS)",
                delta.abs(), baseline.avg_fps, candidate.avg_fps
            )
        } else if delta > threshold_pct {
            format!(
                "Performance IMPROVEMENT detected: +{:.1}% higher average FPS (Baseline: {:.1} FPS vs Candidate: {:.1} FPS)",
                delta, baseline.avg_fps, candidate.avg_fps
            )
        } else {
            format!(
                "Performance stable: {:.1}% change within acceptable threshold tolerance (±{:.1}%)",
                delta, threshold_pct
            )
        };

        RegressionReport {
            game_id: candidate.game_id.clone(),
            baseline_avg_fps: baseline.avg_fps,
            candidate_avg_fps: candidate.avg_fps,
            fps_delta_pct: (delta * 10.0).round() / 10.0,
            is_regression,
            regression_threshold_pct: threshold_pct,
            summary,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_benchmark_session_and_regression() {
        let metrics_base = vec![
            BenchmarkMetric { timestamp_sec: 1.0, fps: 60.0, frametime_ms: 16.6, gpu_load_pct: 75.0 },
            BenchmarkMetric { timestamp_sec: 2.0, fps: 59.0, frametime_ms: 16.9, gpu_load_pct: 76.0 },
            BenchmarkMetric { timestamp_sec: 3.0, fps: 61.0, frametime_ms: 16.3, gpu_load_pct: 74.0 },
        ];
        let session_base = BenchmarkEngine::compute_session("sess_1", "elden_ring", "Apple M2", metrics_base);
        assert_eq!(session_base.avg_fps, 60.0);

        let metrics_bad = vec![
            BenchmarkMetric { timestamp_sec: 1.0, fps: 45.0, frametime_ms: 22.2, gpu_load_pct: 95.0 },
            BenchmarkMetric { timestamp_sec: 2.0, fps: 44.0, frametime_ms: 22.7, gpu_load_pct: 96.0 },
        ];
        let session_bad = BenchmarkEngine::compute_session("sess_2", "elden_ring", "Apple M2", metrics_bad);

        let report = BenchmarkEngine::evaluate_regression(&session_base, &session_bad, 10.0);
        assert!(report.is_regression);
        assert!(report.fps_delta_pct < -20.0);
    }
}
