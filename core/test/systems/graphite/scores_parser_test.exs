defmodule Systems.Graphite.ScoresParserTest do
  use Core.DataCase

  alias Systems.Graphite
  alias Systems.Graphite.ScoresParser
  alias Systems.Graphite.Factories

  describe "from_lines/2" do
    test "error rejected with unknown submission" do
      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "1,git@github.com:eyra/fertility-prediction-challenge.git,92ec9ad16ca8eeb96c3f55bfe2e0261dd36d6874,error,Repo does not have expect Dockerfile with name: Dockerfile,,,,"
        ]
        |> CSV.decode(headers: true)

      leaderboard = Factories.create_leaderboard(%{})

      assert %Systems.Graphite.ScoresParseResult{
               error:
                 {[],
                  [
                    {1,
                     %{
                       "submission-id" => 1,
                       "url" => "git@github.com:eyra/fertility-prediction-challenge.git",
                       "ref" => "92ec9ad16ca8eeb96c3f55bfe2e0261dd36d6874",
                       "status" => "error",
                       "error_message" =>
                         "Repo does not have expect Dockerfile with name: Dockerfile"
                     }, [:missing_submission]}
                  ]},
               success: {[], []}
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "error valid with known submission" do
      tool = Factories.create_tool()
      leaderboard = Factories.create_leaderboard(tool, %{})
      submission = %{id: submission_id} = Factories.add_submission(tool)
      {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)

      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "#{submission.id},#{url},#{ref},error,Repo does not have expect Dockerfile with name: Dockerfile,,,,"
        ]
        |> CSV.decode(headers: true)

      assert %Systems.Graphite.ScoresParseResult{
               error: {
                 [
                   {1,
                    %{
                      "submission-id" => ^submission_id,
                      "url" => ^url,
                      "ref" => ^ref,
                      "status" => "error",
                      "error_message" =>
                        "Repo does not have expect Dockerfile with name: Dockerfile",
                      "submission_record" => {
                        "git@github.com:org/repo.git",
                        "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"
                      }
                    }, []}
                 ],
                 []
               },
               success: {[], []}
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "success rejected with unknown submission" do
      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "1,git@github.com:eyra/fertility-prediction-challenge.git,1caf4130b561896a615cf3278c1cabce9705f0be,success,,0.7772151898734178,0,0.0,0"
        ]
        |> CSV.decode(headers: true)

      leaderboard =
        Factories.create_leaderboard(%{metrics: ["accuracy", "precision", "recall", "f1_score"]})

      assert %Systems.Graphite.ScoresParseResult{
               error: {[], []},
               success:
                 {[],
                  [
                    {1,
                     %{
                       "submission-id" => 1,
                       "url" => "git@github.com:eyra/fertility-prediction-challenge.git",
                       "ref" => "1caf4130b561896a615cf3278c1cabce9705f0be",
                       "status" => "success",
                       "error_message" => "",
                       "accuracy" => 0.7772151898734178,
                       "f1_score" => +0.0,
                       "precision" => +0.0,
                       "recall" => +0.0
                     }, [:missing_submission]}
                  ]}
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "success valid with known submission" do
      tool = Factories.create_tool()

      leaderboard =
        Factories.create_leaderboard(tool, %{
          metrics: ["accuracy", "precision", "recall", "f1_score"]
        })

      submission = %{id: submission_id} = Factories.add_submission(tool)
      {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)

      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,+0.0,0"
        ]
        |> CSV.decode(headers: true)

      assert %Systems.Graphite.ScoresParseResult{
               error: {[], []},
               success: {
                 [
                   {1,
                    %{
                      "submission-id" => ^submission_id,
                      "url" => ^url,
                      "ref" => ^ref,
                      "status" => "success",
                      "error_message" => "",
                      "accuracy" => 0.7772151898734178,
                      "f1_score" => +0.0,
                      "precision" => +0.0,
                      "recall" => +0.0,
                      "submission_record" => {
                        "git@github.com:org/repo.git",
                        "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"
                      }
                    }, []}
                 ],
                 []
               }
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "success valid with empty lines" do
      tool = Factories.create_tool()

      leaderboard =
        Factories.create_leaderboard(tool, %{
          metrics: ["accuracy", "precision", "recall", "f1_score"]
        })

      submission = %{id: submission_id} = Factories.add_submission(tool)
      {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)

      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,+0.0,0",
          ""
        ]
        |> CSV.decode(headers: true)

      assert %Systems.Graphite.ScoresParseResult{
               error: {[], []},
               success: {
                 [
                   {2,
                    %{
                      "submission-id" => ^submission_id,
                      "url" => ^url,
                      "ref" => ^ref,
                      "status" => "success",
                      "error_message" => "",
                      "accuracy" => 0.7772151898734178,
                      "f1_score" => +0.0,
                      "precision" => +0.0,
                      "recall" => +0.0,
                      "submission_record" => {
                        "git@github.com:org/repo.git",
                        "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"
                      }
                    }, []}
                 ],
                 []
               }
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "success valid with empty metric scores" do
      tool = Factories.create_tool()

      leaderboard =
        Factories.create_leaderboard(tool, %{
          metrics: ["accuracy", "precision", "recall", "f1_score"]
        })

      submission = %{id: submission_id} = Factories.add_submission(tool)
      {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)

      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "#{submission.id},#{url},#{ref},success,,,,,"
        ]
        |> CSV.decode(headers: true)

      assert %Systems.Graphite.ScoresParseResult{
               error: {[], []},
               success: {
                 [
                   {1,
                    %{
                      "submission-id" => ^submission_id,
                      "url" => ^url,
                      "ref" => ^ref,
                      "status" => "success",
                      "error_message" => "",
                      "accuracy" => +0.0,
                      "f1_score" => +0.0,
                      "precision" => +0.0,
                      "recall" => +0.0,
                      "submission_record" => {
                        "git@github.com:org/repo.git",
                        "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"
                      }
                    }, []}
                 ],
                 []
               }
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "success invalid with missing metric" do
      tool = Factories.create_tool()

      leaderboard =
        Factories.create_leaderboard(tool, %{
          metrics: ["accuracy", "precision", "recall", "f1_score", "missing_metric"]
        })

      submission = %{id: submission_id} = Factories.add_submission(tool)
      {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)

      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,0.0,0"
        ]
        |> CSV.decode(headers: true)

      assert %Systems.Graphite.ScoresParseResult{
               error: {[], []},
               success:
                 {[],
                  [
                    {1,
                     %{
                       "submission-id" => ^submission_id,
                       "url" => ^url,
                       "ref" => ^ref,
                       "status" => "success",
                       "error_message" => "",
                       "accuracy" => 0.7772151898734178,
                       "f1_score" => +0.0,
                       "precision" => +0.0,
                       "recall" => +0.0,
                       "submission_record" => {
                         "git@github.com:org/repo.git",
                         "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"
                       }
                     }, [:missing_metric]}
                  ]}
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "success invalid with changed submission" do
      tool = Factories.create_tool()

      leaderboard =
        Factories.create_leaderboard(tool, %{
          metrics: ["accuracy", "precision", "recall", "f1_score"]
        })

      submission = %{id: submission_id} = Factories.add_submission(tool)
      {url, _ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)

      ref = random_ref()

      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,0.0,0"
        ]
        |> CSV.decode(headers: true)

      assert %Systems.Graphite.ScoresParseResult{
               error: {[], []},
               success:
                 {[],
                  [
                    {1,
                     %{
                       "submission-id" => ^submission_id,
                       "url" => ^url,
                       "ref" => ^ref,
                       "status" => "success",
                       "error_message" => "",
                       "accuracy" => 0.7772151898734178,
                       "f1_score" => +0.0,
                       "precision" => +0.0,
                       "recall" => +0.0,
                       "submission_record" => {
                         "git@github.com:org/repo.git",
                         "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"
                       }
                     }, [:incorrect_url]}
                  ]}
             } = ScoresParser.from_lines(lines, leaderboard)
    end

    test "real world example" do
      tool = Factories.create_tool()

      leaderboard =
        Factories.create_leaderboard(tool, %{
          metrics: ["accuracy", "precision", "recall", "f1_score"]
        })

      submission = %{id: submission_id} = Factories.add_submission(tool)
      {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)

      lines =
        [
          "submission-id,url,ref,status,error_message,accuracy,precision,recall,f1_score",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,0.0,0",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,0.0,0",
          "#{submission.id},#{url},#{ref},success,,0.8253164556962025,0.6144578313253012,0.5795454545454546,0.5964912280701754",
          "#{submission.id},#{url},#{ref},error,Failed to run container,,,,",
          "#{submission.id},#{url},#{ref},error,Repo does not have expect Dockerfile with name: Dockerfile,,,,",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,0.0,0",
          "#{submission.id},#{url},#{ref},error,Failed to run container,,,,",
          "#{submission.id},#{url},#{ref},error,Failed to run container,,,,",
          "#{submission.id},#{url},#{ref},success,,0.7772151898734178,0,0.0,0",
          "#{submission.id},#{url},#{ref},success,,0.8405063291139241,0.6865671641791045,0.5227272727272727,0.5935483870967742",
          "#{submission.id},#{url},#{ref},error,Failed to reset repo to ref,,,,",
          "#{submission.id},#{url},#{ref},error,Failed to reset repo to ref,,,,",
          "#{submission.id},#{url},#{ref},error,Failed to build image,,,,",
          "#{submission.id},#{url},#{ref},success,,0.7189873417721518,0.20512820512820512,0.09090909090909091,0.12598425196850396",
          "#{submission.id},#{url},#{ref},error,Failed to run container,,,,",
          "#{submission.id},#{url},#{ref},success,,0.8531645569620253,0.7205882352941176,0.5568181818181818,0.6282051282051282",
          "#{submission.id},#{url},#{ref},success,,0.8075949367088607,0.8888888888888888,0.1927710843373494,0.31683168316831684",
          "#{submission.id},#{url},#{ref},success,,0.7670886075949367,0.42857142857142855,0.13636363636363635,0.20689655172413793",
          "#{submission.id},#{url},#{ref},error,Failed to reset repo to ref,,,,"
        ]
        |> CSV.decode(headers: true)

      assert %Systems.Graphite.ScoresParseResult{
               error:
                 {[
                    {4,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to run container",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {5,
                     %{
                       "accuracy" => "",
                       "error_message" =>
                         "Repo does not have expect Dockerfile with name: Dockerfile",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {7,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to run container",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {8,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to run container",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {11,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to reset repo to ref",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {12,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to reset repo to ref",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {13,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to build image",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {15,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to run container",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {19,
                     %{
                       "accuracy" => "",
                       "error_message" => "Failed to reset repo to ref",
                       "f1_score" => "",
                       "precision" => "",
                       "recall" => "",
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "error",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []}
                  ], []},
               success:
                 {[
                    {1,
                     %{
                       "accuracy" => 0.7772151898734178,
                       "error_message" => "",
                       "f1_score" => +0.0,
                       "precision" => +0.0,
                       "recall" => +0.0,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {2,
                     %{
                       "accuracy" => 0.7772151898734178,
                       "error_message" => "",
                       "f1_score" => +0.0,
                       "precision" => +0.0,
                       "recall" => +0.0,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {3,
                     %{
                       "accuracy" => 0.8253164556962025,
                       "error_message" => "",
                       "f1_score" => 0.5964912280701754,
                       "precision" => 0.6144578313253012,
                       "recall" => 0.5795454545454546,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {6,
                     %{
                       "accuracy" => 0.7772151898734178,
                       "error_message" => "",
                       "f1_score" => +0.0,
                       "precision" => +0.0,
                       "recall" => +0.0,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {9,
                     %{
                       "accuracy" => 0.7772151898734178,
                       "error_message" => "",
                       "f1_score" => +0.0,
                       "precision" => +0.0,
                       "recall" => +0.0,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {10,
                     %{
                       "accuracy" => 0.8405063291139241,
                       "error_message" => "",
                       "f1_score" => 0.5935483870967742,
                       "precision" => 0.6865671641791045,
                       "recall" => 0.5227272727272727,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {14,
                     %{
                       "accuracy" => 0.7189873417721518,
                       "error_message" => "",
                       "f1_score" => 0.12598425196850396,
                       "precision" => 0.20512820512820512,
                       "recall" => 0.09090909090909091,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {16,
                     %{
                       "accuracy" => 0.8531645569620253,
                       "error_message" => "",
                       "f1_score" => 0.6282051282051282,
                       "precision" => 0.7205882352941176,
                       "recall" => 0.5568181818181818,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {17,
                     %{
                       "accuracy" => 0.8075949367088607,
                       "error_message" => "",
                       "f1_score" => 0.31683168316831684,
                       "precision" => 0.8888888888888888,
                       "recall" => 0.1927710843373494,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []},
                    {18,
                     %{
                       "accuracy" => 0.7670886075949367,
                       "error_message" => "",
                       "f1_score" => 0.20689655172413793,
                       "precision" => 0.42857142857142855,
                       "recall" => 0.13636363636363635,
                       "ref" => "4cf8a66bcbe349488fabc211e1bfb72007a9f14a",
                       "status" => "success",
                       "submission-id" => ^submission_id,
                       "submission_record" =>
                         {"git@github.com:org/repo.git",
                          "4cf8a66bcbe349488fabc211e1bfb72007a9f14a"},
                       "url" => "git@github.com:org/repo.git"
                     }, []}
                  ], []}
             } = ScoresParser.from_lines(lines, leaderboard)
    end
  end

  defp random_ref() do
    for _ <- 1..40, into: "", do: <<Enum.random(~c"0123456789abcdef")>>
  end
end
